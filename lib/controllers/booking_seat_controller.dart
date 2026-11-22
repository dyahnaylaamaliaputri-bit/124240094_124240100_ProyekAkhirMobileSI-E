// lib/controllers/booking_seat_controller.dart
// Controller pemilihan kursi bioskop multi-studio, concurrency lock, dan timer hold (PB-020, PB-027, PB-028, PB-029)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/booking_order_model.dart';
import '../models/cinema_model.dart';
import '../models/fnb_item_model.dart';
import '../models/fnb_order_model.dart';
import '../models/movie_model.dart';
import '../models/seat_model.dart';
import '../models/showtime_model.dart';
import '../routes/app_routes.dart';
import '../services/seat_service.dart';
import 'auth_controller.dart';

class BookingSeatController extends GetxController {
  MovieModel? _movie;
  MovieModel get movie =>
      _movie ??
      MovieModel(
        id: 1,
        title: 'Cinemate Movie',
        overview: '',
        voteAverage: 8.0,
        voteCount: 100,
        genreIds: [28],
        popularity: 100.0,
      );
  set movie(MovieModel val) => _movie = val;

  CinemaModel? _cinema;
  CinemaModel get cinema =>
      _cinema ??
      CinemaModel(
        id: 'cin-1',
        name: 'Cinemate Cinema',
        address: 'Jakarta',
        latitude: -6.2088,
        longitude: 106.8456,
      );
  set cinema(CinemaModel val) => _cinema = val;

  ShowtimeModel? _showtime;
  ShowtimeModel get showtime =>
      _showtime ??
      ShowtimeModel(
        id: 'st-default',
        cinemaId: cinema.id,
        movieId: movie.id,
        movieTitle: movie.title,
        showDate: DateTime.now().toString().substring(0, 10),
        showTime: '14:00',
        hallName: 'Studio 1',
        experience: 'Regular 2D',
        price: 50000,
        totalSeats: 56,
        availableSeats: 48,
      );
  set showtime(ShowtimeModel val) => _showtime = val;

  final SeatService _seatService;

  BookingSeatController({SeatService? seatService})
      : _seatService = seatService ?? SeatService.instance;

  /// Daftar baris kursi di studio (reaktif sesuai tipe studio)
  final rows = <String>['A', 'B', 'C', 'D', 'E', 'F', 'G'].obs;

  /// Jumlah kursi per baris (reaktif)
  final seatsPerRow = 8.obs;

  /// Map seluruh kursi: "A1" -> SeatModel
  final seatsMap = <String, SeatModel>{}.obs;

  /// Daftar kursi yang sedang dipilih pengguna (misal: ["C4", "C5"])
  final selectedSeats = <String>[].obs;

  /// Maksimal kursi per pemesanan (PB-027: pembatasan 6 kursi anti-calo)
  final int maxSeats = 6;

  /// Durasi temporary hold kursi (PB-029: 10 menit = 600 detik)
  static const int defaultHoldDurationSeconds = 600;

  /// Sisa detik waktu penahanan kursi
  final holdRemainingSeconds = defaultHoldDurationSeconds.obs;

  /// Status apakah timer penahanan kursi sedang aktif
  final isHoldingSeats = false.obs;

  Timer? _holdTimer;

  /// Waktu kedaluwarsa kunci kursi saat ini
  final holdExpiryTime = Rxn<DateTime>();

  /// ID Pengguna saat ini
  String get currentUserId {
    try {
      if (Get.isRegistered<AuthController>()) {
        final user = Get.find<AuthController>().currentUser.value;
        if (user != null && user.id.isNotEmpty) return user.id;
      }
    } catch (_) {}
    return 'usr-guest-${showtime.id.hashCode.abs() % 10000}';
  }

  @override
  void onInit() {
    super.onInit();
    _initArguments();
    _configureStudioLayout();
    _generateSeatsLayout();
  }

  @override
  void onClose() {
    _holdTimer?.cancel();
    super.onClose();
  }

  void _initArguments() {
    final args = Get.arguments;
    if (args is Map) {
      if (_movie == null && args['movie'] is MovieModel) {
        _movie = args['movie'] as MovieModel;
      }
      if (_cinema == null && args['cinema'] is CinemaModel) {
        _cinema = args['cinema'] as CinemaModel;
      }
      if (_showtime == null && args['showtime'] is ShowtimeModel) {
        _showtime = args['showtime'] as ShowtimeModel;
      }
    }
  }

  /// Menyesuaikan denah tata letak kursi berdasarkan kelas studio (PB-027 Multi-Studio)
  void _configureStudioLayout() {
    final exp = showtime.experience.toLowerCase();
    if (exp.contains('imax') ||
        exp.contains('laser') ||
        exp.contains('ultra')) {
      // IMAX with Laser: 10 baris (A s/d J) x 12 kursi = 120 kursi
      rows.assignAll(['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J']);
      seatsPerRow.value = 12;
    } else if (exp.contains('premiere') ||
        exp.contains('velvet') ||
        exp.contains('gold') ||
        exp.contains('vip')) {
      // The Premiere / Velvet: 4 baris (A s/d D) x 6 kursi = 24 kursi (Plush Recliner)
      rows.assignAll(['A', 'B', 'C', 'D']);
      seatsPerRow.value = 6;
    } else {
      // Regular 2D / Standar: 7 baris (A s/d G) x 8 kursi = 56 kursi
      rows.assignAll(['A', 'B', 'C', 'D', 'E', 'F', 'G']);
      seatsPerRow.value = 8;
    }
  }

  /// Total kapasitas kursi studio saat ini
  int get totalStudioSeats => rows.length * seatsPerRow.value;

  /// Menghasilkan tata letak kursi, menandai reserved & locked (PB-027, PB-028)
  void _generateSeatsLayout() {
    final seed = showtime.id.hashCode.abs();
    final reservedSet = <String>{};

    // Tentukan kursi yang sudah dipesan (reserved)
    for (final r in rows) {
      for (int c = 1; c <= seatsPerRow.value; c++) {
        final id = '$r$c';
        final hash = (seed + id.hashCode).abs();
        if (hash % 5 == 0 && reservedSet.length < (totalStudioSeats ~/ 5)) {
          reservedSet.add(id);
        }
      }
    }

    final exp = showtime.experience.toLowerCase();
    final isPremiere = exp.contains('premiere') || exp.contains('velvet');
    final isImax = exp.contains('imax');

    final newMap = <String, SeatModel>{};
    for (final r in rows) {
      for (int c = 1; c <= seatsPerRow.value; c++) {
        final id = '$r$c';
        final isReserved = reservedSet.contains(id);

        SeatType type = SeatType.regular;
        int price = showtime.price;

        if (isPremiere) {
          type = SeatType.recliner;
        } else if (isImax && r == 'J') {
          // Baris belakang IMAX adalah Sweetbox sofa berpasangan
          type = SeatType.sweetbox;
          price = showtime.price + 20000;
        }

        newMap[id] = SeatModel(
          id: id,
          row: r,
          column: c,
          status: isReserved ? SeatStatus.reserved : SeatStatus.available,
          type: type,
          price: price,
        );
      }
    }
    seatsMap.value = newMap;

    // Muat kursi yang sedang dikunci pengguna lain (PB-028 Concurrency Lock)
    refreshLockedSeats();
  }

  /// Memperbarui status kursi yang sedang dikunci pengguna lain secara real-time
  Future<void> refreshLockedSeats() async {
    try {
      final lockedLabels = await _seatService.getLockedSeatLabels(
        showtime.id,
        excludeUserId: currentUserId,
      );

      for (final seatLabel in lockedLabels) {
        final currentSeat = seatsMap[seatLabel];
        if (currentSeat != null && !currentSeat.isReserved) {
          seatsMap[seatLabel] = currentSeat.copyWith(status: SeatStatus.locked);
          // Jika kursi ini sebelumnya dipilih pengguna lokal, lepaskan seleksi
          if (selectedSeats.contains(seatLabel)) {
            selectedSeats.remove(seatLabel);
          }
        }
      }
    } catch (e) {
      debugPrint('[BookingSeatController] Error refreshLockedSeats: $e');
    }
  }

  /// Toggle seleksi kursi pengguna (PB-027 batas 6 kursi & PB-028 proteksi locked)
  void toggleSeat(String seatId) {
    final seat = seatsMap[seatId];
    if (seat == null || seat.isReserved) return;

    // Jika kursi sedang dikunci pengguna lain (PB-028)
    if (seat.isLocked) {
      _showSnackbar(
        title: 'Kursi Sedang Dikunci',
        message:
            'Kursi $seatId sedang diproses oleh pengguna lain. Silakan pilih kursi lain.',
        icon: Icons.lock_clock_rounded,
        iconColor: const Color(0xFFFFD700),
      );
      return;
    }

    if (selectedSeats.contains(seatId)) {
      selectedSeats.remove(seatId);
      seatsMap[seatId] = seat.copyWith(status: SeatStatus.available);
    } else {
      // Validasi batas maksimal 6 kursi per transaksi (PB-027)
      if (selectedSeats.length >= maxSeats) {
        _showSnackbar(
          title: 'Batas Kursi Tercapai',
          message:
              'Anda hanya dapat memilih maksimal $maxSeats kursi dalam satu pemesanan.',
          icon: Icons.info_outline,
          iconColor: const Color(0xFFFFD700),
        );
        return;
      }
      selectedSeats.add(seatId);
      seatsMap[seatId] = seat.copyWith(status: SeatStatus.selected);
    }
  }

  /// Memulai timer temporary hold 10 menit (PB-029)
  void startHoldTimer({int initialSeconds = defaultHoldDurationSeconds}) {
    _holdTimer?.cancel();
    holdRemainingSeconds.value = initialSeconds;
    isHoldingSeats.value = true;
    holdExpiryTime.value =
        DateTime.now().add(Duration(seconds: initialSeconds));

    _holdTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (holdRemainingSeconds.value > 0) {
        holdRemainingSeconds.value--;
      } else {
        timer.cancel();
        _handleHoldTimerExpired();
      }
    });
  }

  /// Menghentikan timer hold kursi
  void stopHoldTimer() {
    _holdTimer?.cancel();
    _holdTimer = null;
    isHoldingSeats.value = false;
    holdExpiryTime.value = null;
  }

  /// Format hitung mundur mm:ss untuk UI (misal: "09:45")
  String get formattedHoldTimer {
    final mins = (holdRemainingSeconds.value ~/ 60).toString().padLeft(2, '0');
    final secs = (holdRemainingSeconds.value % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  /// Penanganan saat waktu penahanan 10 menit kedaluwarsa (PB-029 Auto-release)
  Future<void> _handleHoldTimerExpired() async {
    isHoldingSeats.value = false;
    await releaseHeldSeats();

    // Reset status kursi yang dipilih kembali ke available
    for (final seatId in selectedSeats) {
      final seat = seatsMap[seatId];
      if (seat != null) {
        seatsMap[seatId] = seat.copyWith(status: SeatStatus.available);
      }
    }
    selectedSeats.clear();

    _showSnackbar(
      title: 'Waktu Penahanan Habis',
      message:
          'Waktu pemesanan kursi 10 menit telah kedaluwarsa. Kursi Anda telah dilepas kembali.',
      icon: Icons.timer_off_rounded,
      iconColor: const Color(0xFFE50914),
    );
  }

  /// Melepaskan kursi yang dikunci oleh pengguna saat ini
  Future<void> releaseHeldSeats() async {
    if (selectedSeats.isEmpty) return;
    try {
      await _seatService.releaseSeats(
        showtimeId: showtime.id,
        seatLabels: List<String>.from(selectedSeats),
        userId: currentUserId,
      );
      stopHoldTimer();
    } catch (e) {
      debugPrint('[BookingSeatController] Error releaseHeldSeats: $e');
    }
  }

  /// Total harga tiket berdasarkan jumlah kursi terpilih
  int get subtotal {
    int total = 0;
    for (final seatId in selectedSeats) {
      final seat = seatsMap[seatId];
      if (seat != null) {
        total += seat.price;
      } else {
        total += showtime.price;
      }
    }
    return total;
  }

  /// String rupiah subtotal
  String get formattedSubtotal => BookingOrderModel.formatRupiah(subtotal);

  /// Label kursi terpilih (misal: "A1, A2")
  String get selectedSeatsLabel {
    if (selectedSeats.isEmpty) return 'Belum ada kursi yang dipilih';
    final sorted = List<String>.from(selectedSeats)..sort();
    return sorted.join(', ');
  }

  /// List item F&B tambahan opsional (PB-032 / FR-028)
  final selectedFnbItems = <String, int>{}.obs;

  void addFnbItem(String itemId) {
    selectedFnbItems[itemId] = (selectedFnbItems[itemId] ?? 0) + 1;
  }

  void removeFnbItem(String itemId) {
    if (!selectedFnbItems.containsKey(itemId)) return;
    if (selectedFnbItems[itemId]! <= 1) {
      selectedFnbItems.remove(itemId);
    } else {
      selectedFnbItems[itemId] = selectedFnbItems[itemId]! - 1;
    }
  }

  int get fnbAddonTotal {
    int total = 0;
    for (final entry in selectedFnbItems.entries) {
      final item =
          FnbItemModel.seedItems.firstWhereOrNull((it) => it.id == entry.key);
      if (item != null) {
        total += item.price * entry.value;
      }
    }
    return total;
  }

  String get formattedFnbAddonTotal =>
      BookingOrderModel.formatRupiah(fnbAddonTotal);

  /// Melanjutkan ke halaman Ringkasan Pesanan dengan concurrency locking (PB-028 & PB-029)
  Future<void> proceedToOrderSummary(
      {List<FnbOrderItemModel>? directFnbItems}) async {
    if (selectedSeats.isEmpty) {
      _showSnackbar(
        title: 'Pilih Kursi',
        message: 'Silakan pilih minimal 1 kursi bioskop untuk melanjutkan.',
        icon: Icons.event_seat_rounded,
        iconColor: const Color(0xFFE50914),
      );
      return;
    }

    // PB-028: Concurrency Lock Check ke SeatService
    final lockResult = await _seatService.lockSeats(
      showtimeId: showtime.id,
      seatLabels: List<String>.from(selectedSeats),
      userId: currentUserId,
      holdDuration: const Duration(seconds: defaultHoldDurationSeconds),
    );

    // Jika terjadi bentrok dengan pengguna lain (PB-028 Collision Detection)
    if (!lockResult.isSuccess) {
      for (final conflictSeat in lockResult.conflictingSeats) {
        selectedSeats.remove(conflictSeat);
        final currentSeat = seatsMap[conflictSeat];
        if (currentSeat != null) {
          seatsMap[conflictSeat] =
              currentSeat.copyWith(status: SeatStatus.locked);
        }
      }

      _showSnackbar(
        title: 'Kursi Baru Saja Dipilih Pengguna Lain',
        message: lockResult.message,
        icon: Icons.warning_amber_rounded,
        iconColor: const Color(0xFFFFD700),
      );
      return;
    }

    // PB-029: Mulai timer penahanan 10 menit saat berhasil mengunci kursi
    startHoldTimer();

    final List<FnbOrderItemModel> fnbList = [];
    if (directFnbItems != null) {
      fnbList.addAll(directFnbItems);
    } else {
      for (final entry in selectedFnbItems.entries) {
        final item =
            FnbItemModel.seedItems.firstWhereOrNull((it) => it.id == entry.key);
        if (item != null) {
          fnbList.add(FnbOrderItemModel(
            fnbItemId: item.id,
            name: item.name,
            price: item.price,
            quantity: entry.value,
            subtotal: item.price * entry.value,
          ));
        }
      }
    }

    final orderId =
        'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    final order = BookingOrderModel(
      id: orderId,
      movie: movie,
      cinema: cinema,
      showtime: showtime,
      selectedSeats: List<String>.from(selectedSeats)..sort(),
      ticketPrice: showtime.price,
      serviceFeePerTicket: 3000,
      fnbItems: fnbList,
      createdAt: DateTime.now(),
      status: 'pending',
    );

    Get.toNamed(Routes.orderSummary, arguments: order);
  }

  void _showSnackbar({
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
  }) {
    if (Get.context != null) {
      Get.snackbar(
        title,
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF16213E),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        icon: Icon(icon, color: iconColor),
      );
    }
  }
}
