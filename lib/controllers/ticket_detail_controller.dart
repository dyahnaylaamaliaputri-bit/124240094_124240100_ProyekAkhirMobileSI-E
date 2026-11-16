// lib/controllers/ticket_detail_controller.dart
// Controller untuk melihat detail E-Ticket, QR Code, & Bagikan Tiket (PB-022, PB-024, PB-025, PB-026C)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../models/ticket_model.dart';
import '../services/ticket_service.dart';
import '../utils/app_colors.dart';
import 'tickets_controller.dart';

class TicketDetailController extends GetxController {
  late final Rx<TicketModel> ticket;

  @override
  void onInit() {
    super.onInit();
    _initTicket();
  }

  void _initTicket() {
    final args = Get.arguments;
    if (args is TicketModel) {
      ticket = Rx<TicketModel>(args);
    } else {
      // Fallback demo ticket
      ticket = Rx<TicketModel>(
        TicketModel(
          id: 'TKT-DEMO-001',
          bookingCode: 'CNM-78429',
          userId: 'usr-1',
          showtimeId: 'st-101',
          movieId: 533535,
          movieTitle: 'Deadpool & Wolverine',
          posterPath: '/8cdWjvZQUExUUTzyp4t6EDMubfO.jpg',
          cinemaId: 'cin-1',
          cinemaName: 'Metro Cinema Senayan',
          cinemaAddress: 'Jl. Asia Afrika No. 8, Jakarta Selatan',
          hallName: 'Studio 1',
          experience: 'Regular 2D',
          showDate: '2026-11-07',
          showTime: '14:00',
          seats: ['C2', 'C3'],
          totalPrice: 106000,
          qrData: 'CINEMATE:CNM-78429:2026-11-07:14:00:C2,C3',
          status: 'paid',
          paymentMethod: 'QRIS Bersama',
          paymentReference: 'PAY-28693526',
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  /// Format teks undangan nonton & rincian e-ticket (PB-026C)
  static String formatShareMessage(TicketModel ticket) {
    return '🎬 *Undangan Nonton Bareng - CINEMATE*\n\n'
        'Hai! Aku mengundangmu untuk menonton:\n'
        '🍿 Film: *${ticket.movieTitle}*\n'
        '📍 Bioskop: ${ticket.cinemaName} (${ticket.hallName} - ${ticket.experience})\n'
        '📅 Jadwal: ${ticket.formattedShowDate} • ${ticket.showTime} WIB\n'
        '💺 Kursi: ${ticket.seatsLabel} (${ticket.seatCount} Tiket)\n'
        '🎟️ Kode Booking: *${ticket.bookingCode}*\n\n'
        'Tunjukkan e-ticket atau sebutkan kode booking ini saat tiba di bioskop.\n'
        'Pesan tiket bioskop mudah & cepat hanya di Cinemate! 🎟️✨';
  }

  /// Ringkasan pesan bagikan untuk tiket saat ini
  String get shareMessage => formatShareMessage(ticket.value);

  /// Bagikan e-ticket / undangan nonton via Share dialog sistem atau Clipboard fallback (PB-026C)
  Future<void> shareTicket() async {
    final text = shareMessage;
    try {
      final result = await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: 'Undangan Nonton: ${ticket.value.movieTitle} di ${ticket.value.cinemaName}',
        ),
      );
      if (result.status == ShareResultStatus.success) {
        Get.snackbar(
          'Tiket Dibagikan 🎉',
          'Undangan tiket bioskop berhasil dibagikan!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.card,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (_) {
      // Fallback ke Clipboard jika share intent sistem tidak tersedia
      await Clipboard.setData(ClipboardData(text: text));
      Get.snackbar(
        'Tersalin ke Clipboard 📋',
        'Format undangan tiket ${ticket.value.bookingCode} berhasil disalin ke papan klip.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.card,
        colorText: Colors.white,
        icon: const Icon(Icons.copy_rounded, color: AppColors.gold),
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Salin kode booking tiket
  void copyBookingCode() {
    Clipboard.setData(ClipboardData(text: ticket.value.bookingCode));
    Get.snackbar(
      'Kode Booking Tersalin',
      'Kode ${ticket.value.bookingCode} berhasil disalin ke clipboard.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF16213E),
      colorText: const Color(0xFFFFFFFF),
      duration: const Duration(seconds: 2),
    );
  }

  /// Simulasi Check-in / Scan QR untuk menandai tiket telah digunakan (PB-025, PB-026B)
  Future<void> simulateCheckIn() async {
    final updated = await TicketService().updateTicketStatus(
      ticketId: ticket.value.id,
      newStatus: 'used',
    );
    if (updated != null) {
      ticket.value = updated;
      if (Get.isRegistered<TicketsController>()) {
        Get.find<TicketsController>().loadTickets(forceRefresh: true);
      }
      Get.snackbar(
        'Check-in Berhasil 🎉',
        'Tiket ${ticket.value.bookingCode} berhasil dipindai dan dipindahkan ke Riwayat.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.card,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle_rounded, color: AppColors.success),
      );
    }
  }
}
