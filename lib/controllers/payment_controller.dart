// lib/controllers/payment_controller.dart
// Controller simulasi pembayaran tiket bioskop (PB-021)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../models/booking_order_model.dart';
import '../models/cinema_model.dart';
import '../models/movie_model.dart';
import '../models/payment_method_model.dart';
import '../models/showtime_model.dart';
import '../models/ticket_model.dart';
import '../routes/app_routes.dart';
import '../services/storage_service.dart';
import '../services/ticket_service.dart';
import '../services/notification_service.dart';
import '../services/fnb_service.dart';
import '../utils/app_colors.dart';
import '../views/booking/widgets/payment_success_sheet.dart';
import 'fnb_controller.dart';
import 'tickets_controller.dart';

class PaymentController extends GetxController {
  late final Rx<BookingOrderModel> order;

  /// Daftar semua metode pembayaran
  final allMethods = PaymentMethodModel.predefinedMethods;

  /// Kategori metode pembayaran yang dipilih (Virtual Account / E-Wallet / QRIS)
  final selectedCategory = PaymentCategory.virtualAccount.obs;

  /// Metode pembayaran spesifik yang dipilih
  late final Rx<PaymentMethodModel> selectedMethod;

  /// Timer hitung mundur 10 menit (600 detik)
  final remainingSeconds = 600.obs;
  Timer? _countdownTimer;

  /// Status proses pembayaran
  final isProcessing = false.obs;
  final isPaymentSuccess = false.obs;
  final createdTicket = Rx<TicketModel?>(null);

  /// Input nomor ponsel untuk E-Wallet (diisi manual oleh pengguna)
  final phoneController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _initOrder();
    selectedMethod = Rx<PaymentMethodModel>(allMethods.first);
    _startCountdownTimer();
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    phoneController.dispose();
    super.onClose();
  }

  void _initOrder() {
    final args = Get.arguments;
    if (args is BookingOrderModel) {
      order = Rx<BookingOrderModel>(args);
    } else {
      order = Rx<BookingOrderModel>(
        BookingOrderModel(
          id: 'ORD-DEMO-021',
          movie: MovieModel(
            id: 533535,
            title: 'Deadpool & Wolverine',
            overview: 'Wade Wilson and Logan team up.',
            voteAverage: 7.9,
            voteCount: 1500,
            genreIds: [28, 35],
            popularity: 300.0,
          ),
          cinema: CinemaModel(
            id: 'cin-1',
            name: 'Metro Cinema Senayan',
            address: 'Jl. Asia Afrika No. 8, Jakarta Selatan',
            latitude: -6.2176,
            longitude: 106.8013,
          ),
          showtime: ShowtimeModel(
            id: 'st-101',
            cinemaId: 'cin-1',
            movieId: 533535,
            movieTitle: 'Deadpool & Wolverine',
            showDate: '2026-11-07',
            showTime: '14:00',
            hallName: 'Studio 1',
            experience: 'Regular 2D',
            price: 50000,
            totalSeats: 56,
            availableSeats: 48,
          ),
          selectedSeats: ['C2', 'C3'],
          ticketPrice: 50000,
          serviceFeePerTicket: 3000,
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  /// Memulai timer hitung mundur pembayaran 10 menit
  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds.value > 0) {
        remainingSeconds.value--;
      } else {
        timer.cancel();
        _handleOrderExpired();
      }
    });
  }

  /// Format MM:SS untuk countdown timer
  String get formattedTimer {
    final m = (remainingSeconds.value ~/ 60).toString().padLeft(2, '0');
    final s = (remainingSeconds.value % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Penanganan saat batas waktu bayar habis
  void _handleOrderExpired() {
    order.value = order.value.copyWith(status: 'expired');
    Get.dialog(
      PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.timer_off_rounded, color: Color(0xFFE53935)),
              SizedBox(width: 10),
              Text('Waktu Habis',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Batas waktu pembayaran 10 menit telah berakhir. Kursi pesanan Anda telah dilepaskan kembali.',
            style: TextStyle(color: Color(0xFFB0B0B0), fontSize: 14),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE50914),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Get.until((route) => route.settings.name == Routes.dashboard);
              },
              child: const Text('Kembali ke Dashboard',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Mengubah kategori metode pembayaran (VA / E-Wallet / QRIS)
  void selectCategory(PaymentCategory category) {
    selectedCategory.value = category;
    final matching = allMethods.where((m) => m.category == category).toList();
    if (matching.isNotEmpty) {
      selectedMethod.value = matching.first;
    }
  }

  /// Memilih metode pembayaran tertentu
  void selectMethod(PaymentMethodModel method) {
    selectedMethod.value = method;
  }

  /// Menyalin teks nomor VA ke clipboard
  void copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text.replaceAll(' ', '')));
    Get.snackbar(
      'Tersalin!',
      'Nomor Virtual Account telah disalin ke clipboard.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF16213E),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      icon: const Icon(Icons.copy_rounded, color: Color(0xFF4CAF50)),
    );
  }

  /// Validasi nomor HP E-Wallet sebelum memproses pembayaran
  String? validateEWalletPhone() {
    if (selectedCategory.value != PaymentCategory.eWallet) return null;
    final digits = phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return 'Masukkan nomor HP akun ${selectedMethod.value.name} Anda terlebih dahulu.';
    }
    if (digits.length < 10 || digits.length > 15) {
      return 'Masukkan nomor HP yang valid (10-15 digit).';
    }
    return null;
  }

  /// Simulasi Proses Pembayaran Menjadi "PAID" (PB-021)
  Future<void> payNow() async {
    if (isProcessing.value) return;

    final ewalletError = validateEWalletPhone();
    if (ewalletError != null) {
      if (Get.context != null) {
        Get.snackbar(
          'Nomor HP Diperlukan',
          ewalletError,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.card,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
      return;
    }

    isProcessing.value = true;

    // Simulasi jeda pemrosesan jaringan perbankan / gateway (1.5 detik)
    await Future.delayed(const Duration(milliseconds: 1500));

    final ref =
        'PAY-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    final updated = order.value.copyWith(
      status: 'paid',
      paymentMethod: selectedMethod.value.name,
      paidAt: DateTime.now(),
      paymentReference: ref,
    );

    order.value = updated;

    // Simpan ke Supabase & Hive via TicketService (PB-022, PB-023)
    final userId = await StorageService().getUserId() ?? 'usr-local';
    final ticket =
        await TicketService().createBooking(order: updated, userId: userId);
    createdTicket.value = ticket;

    // Sinkronkan ke TicketsController jika terdaftar
    try {
      if (Get.isRegistered<TicketsController>()) {
        Get.find<TicketsController>().loadTickets(forceRefresh: true);
      }
    } catch (_) {}

    // Jika pesanan memuat camilan F&B bundling (PB-032), otomatis buat pesanan F&B di Concession
    if (updated.fnbItems.isNotEmpty) {
      try {
        final fnbOrder = await FnbService().createOrder(
          userId: userId,
          cinemaId: updated.cinema.id,
          cinemaName: updated.cinema.name,
          items: updated.fnbItems,
          pickupMethod: 'counter',
          paymentMethod: selectedMethod.value.name,
        );
        debugPrint(
            '[PaymentController] Berhasil membuat pesanan bundling F&B: ${fnbOrder.pickupCode}');
        if (Get.isRegistered<FnbController>()) {
          Get.find<FnbController>().fetchUserOrders();
        }
      } catch (e) {
        debugPrint(
            '[PaymentController] Error auto-creating bundling F&B order: $e');
      }
    }

    // PB-056: Notifikasi Konfirmasi Pemesanan Tiket Bioskop
    // PB-057: Notifikasi Pengingat Jadwal Film Terjadwal (H-2 jam & H-30 menit)
    try {
      await NotificationService.instance.showTicketConfirmation(ticket);
      await NotificationService.instance.scheduleTicketReminders(ticket);
    } catch (e) {
      debugPrint('[PaymentController] Error sending local notification: $e');
    }

    isProcessing.value = false;
    isPaymentSuccess.value = true;
    _countdownTimer?.cancel();

    _showPaymentSuccessDialog();
  }

  /// Menampilkan dialog / modal sukses pembayaran
  void _showPaymentSuccessDialog() {
    Get.bottomSheet(
      PaymentSuccessSheet(
        order: order.value,
        onGoHome: () {
          Get.until((route) => route.settings.name == Routes.dashboard);
        },
        onViewTicket: () {
          Get.back(); // tutup modal
          if (createdTicket.value != null) {
            Get.toNamed(Routes.ticketDetail, arguments: createdTicket.value);
          } else {
            Get.toNamed(Routes.ticketDetail);
          }
        },
      ),
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
    );
  }
}
