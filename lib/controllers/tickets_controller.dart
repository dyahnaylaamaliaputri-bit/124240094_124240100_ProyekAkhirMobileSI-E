// lib/controllers/tickets_controller.dart
// Controller untuk Tab Tiket Saya: Tiket Aktif, Riwayat, Akses Offline, & Auto Expiry / Scanner Check-in (PB-023 s.d. PB-026C)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/ticket_model.dart';
import '../services/storage_service.dart';
import '../services/ticket_service.dart';
import '../utils/app_colors.dart';

class TicketsController extends GetxController {
  final TicketService _ticketService = TicketService();
  final StorageService _storage = StorageService();

  final activeTickets = <TicketModel>[].obs;
  final historyTickets = <TicketModel>[].obs;
  final isLoading = false.obs;
  final isOfflineMode = false.obs;
  final lastCachedAt = Rxn<DateTime>();
  final searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadTickets();
  }

  /// Memuat seluruh tiket pengguna dari Hive cache / Supabase (PB-024, PB-025, PB-026)
  Future<void> loadTickets({bool forceRefresh = false}) async {
    isLoading.value = true;
    try {
      final userId = await _storage.getUserId() ?? '';
      final result = await _ticketService.getUserTicketsWithMeta(
        userId: userId,
        forceRefresh: forceRefresh,
      );

      isOfflineMode.value = result.isOffline;
      lastCachedAt.value = result.cachedAt;

      final active = <TicketModel>[];
      final history = <TicketModel>[];

      for (final t in result.tickets) {
        if (t.isTicketActive) {
          active.add(t);
        } else {
          history.add(t);
        }
      }

      activeTickets.value = active;
      historyTickets.value = history;

      // Otomatis tandai tiket yang jadwalnya telah lewat menjadi expired (PB-026)
      await autoExpirePastTickets();
    } catch (_) {
      isOfflineMode.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  /// Memeriksa dan mengubah status tiket yang jadwal tayangnya sudah lewat menjadi 'expired' (PB-026)
  Future<int> autoExpirePastTickets() async {
    int count = 0;
    final now = DateTime.now();
    final toExpire = <TicketModel>[];

    // Cek tiket aktif yang jadwal tayangnya telah lewat (lebih dari 24 jam)
    for (final ticket in List<TicketModel>.from(activeTickets)) {
      if (ticket.isShowPassed && ticket.isActive) {
        toExpire.add(ticket);
      }
    }

    // Cek juga tiket di riwayat yang statusnya masih 'paid'/'active' tapi jadwalnya telah lewat
    for (final ticket in List<TicketModel>.from(historyTickets)) {
      if (ticket.isShowPassed && ticket.isActive) {
        toExpire.add(ticket);
      }
    }

    for (final ticket in toExpire) {
      try {
        final updated = await _ticketService.updateTicketStatus(
          ticketId: ticket.id,
          newStatus: 'expired',
        );

        activeTickets.removeWhere(
            (t) => t.id == ticket.id || t.bookingCode == ticket.bookingCode);
        final newTicket = updated ?? ticket.copyWith(status: 'expired');
        historyTickets.removeWhere(
            (t) => t.id == ticket.id || t.bookingCode == ticket.bookingCode);
        historyTickets.insert(0, newTicket);
        count++;
      } catch (e) {
        debugPrint(
            '[TicketsController] Gagal auto-expire tiket ${ticket.bookingCode}: $e');
      }
    }

    return count;
  }

  /// Memvalidasi kode booking (dari QR Code atau input manual) dan melakukan check-in (PB-026B)
  Future<({bool success, String message, TicketModel? ticket})>
      validateAndCheckInBookingCode(String rawCode) async {
    final trimmed = rawCode.trim();
    if (trimmed.isEmpty) {
      return (
        success: false,
        message: 'Kode booking tidak boleh kosong.',
        ticket: null,
      );
    }

    // Ekstraksi kode booking jika format QR adalah "CINEMATE:CNM-XXXXX:..."
    String cleanCode = trimmed;
    if (cleanCode.contains('CINEMATE:')) {
      final parts = cleanCode.split(':');
      if (parts.length >= 2 && parts[1].startsWith('CNM-')) {
        cleanCode = parts[1];
      }
    } else {
      // Cari substring dengan format CNM-XXXXX jika ada
      final match =
          RegExp(r'CNM-\w+', caseSensitive: false).firstMatch(cleanCode);
      if (match != null) {
        cleanCode = match.group(0)!.toUpperCase();
      } else {
        cleanCode = cleanCode.toUpperCase();
      }
    }

    // 1. Cari tiket di activeTickets, historyTickets, atau dari database/Hive
    TicketModel? targetTicket;

    final inActive = activeTickets.firstWhereOrNull(
        (t) => t.bookingCode.toUpperCase() == cleanCode || t.id == cleanCode);
    if (inActive != null) {
      targetTicket = inActive;
    } else {
      final inHistory = historyTickets.firstWhereOrNull(
          (t) => t.bookingCode.toUpperCase() == cleanCode || t.id == cleanCode);
      if (inHistory != null) {
        targetTicket = inHistory;
      } else {
        final all = await _ticketService.getUserTickets();
        targetTicket = all.firstWhereOrNull((t) =>
            t.bookingCode.toUpperCase() == cleanCode || t.id == cleanCode);
      }
    }

    // 2. Evaluasi status tiket
    if (targetTicket == null) {
      return (
        success: false,
        message:
            'Kode booking "$cleanCode" tidak ditemukan dalam sistem bioskop.',
        ticket: null,
      );
    }

    if (targetTicket.status == 'used') {
      return (
        success: false,
        message:
            'Tiket ${targetTicket.bookingCode} (${targetTicket.movieTitle}) sudah pernah digunakan untuk check-in sebelumnya.',
        ticket: targetTicket,
      );
    }

    if (targetTicket.status == 'expired' ||
        targetTicket.status == 'cancelled' ||
        targetTicket.isShowPassed) {
      return (
        success: false,
        message:
            'Tiket ${targetTicket.bookingCode} tidak dapat digunakan karena jadwal telah kedaluwarsa atau dibatalkan.',
        ticket: targetTicket,
      );
    }

    // 3. Eksekusi Check-in: Ubah status menjadi 'used'
    try {
      final updated = await _ticketService.updateTicketStatus(
        ticketId: targetTicket.id,
        newStatus: 'used',
      );

      final resultTicket = updated ?? targetTicket.copyWith(status: 'used');

      // Update state
      activeTickets.removeWhere((t) =>
          t.id == targetTicket!.id ||
          t.bookingCode == targetTicket.bookingCode);
      historyTickets.removeWhere((t) =>
          t.id == targetTicket!.id ||
          t.bookingCode == targetTicket.bookingCode);
      historyTickets.insert(0, resultTicket);

      return (
        success: true,
        message:
            'Check-in Berhasil! Penonton diizinkan masuk ke ${resultTicket.hallName} (${resultTicket.cinemaName}). Kursi: ${resultTicket.seatsLabel}.',
        ticket: resultTicket,
      );
    } catch (e) {
      return (
        success: false,
        message: 'Gagal memperbarui status check-in: $e',
        ticket: targetTicket,
      );
    }
  }

  /// Tiket Aktif terfilter pencarian
  List<TicketModel> get displayedActiveTickets {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return activeTickets;
    return activeTickets.where((t) {
      return t.movieTitle.toLowerCase().contains(q) ||
          t.bookingCode.toLowerCase().contains(q) ||
          t.cinemaName.toLowerCase().contains(q);
    }).toList();
  }

  /// Riwayat Tiket terfilter pencarian
  List<TicketModel> get displayedHistoryTickets {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return historyTickets;
    return historyTickets.where((t) {
      return t.movieTitle.toLowerCase().contains(q) ||
          t.bookingCode.toLowerCase().contains(q) ||
          t.cinemaName.toLowerCase().contains(q);
    }).toList();
  }

  /// Update pencarian
  void updateSearch(String val) {
    searchQuery.value = val;
  }

  /// Format waktu tersimpan cache lokal Hive
  String get formattedCacheTime {
    final dt = lastCachedAt.value;
    if (dt == null) return 'Tersimpan Offline di Hive';
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return 'Tersimpan di Hive ($hour:$minute WIB)';
  }

  /// Simulasi Check-in / Scan QR untuk menandai tiket telah digunakan (PB-025, PB-026B)
  Future<void> markTicketAsUsed(TicketModel ticket) async {
    final result = await validateAndCheckInBookingCode(ticket.bookingCode);
    if (result.success) {
      Get.snackbar(
        'Check-in Berhasil 🎉',
        'Tiket ${ticket.bookingCode} (${ticket.movieTitle}) telah dipindai dan dipindahkan ke Riwayat.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.card,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.check_circle_rounded, color: AppColors.success),
      );
    } else {
      Get.snackbar(
        'Check-in Gagal ⚠️',
        result.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.card,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        icon:
            const Icon(Icons.error_outline_rounded, color: Colors.orangeAccent),
      );
    }
  }
}
