// test/payment_simulation_test.dart
// Pengujian unit simulasi pembayaran tiket bioskop (PB-021)

import 'package:cinemate/controllers/payment_controller.dart';
import 'package:cinemate/models/booking_order_model.dart';
import 'package:cinemate/models/cinema_model.dart';
import 'package:cinemate/models/movie_model.dart';
import 'package:cinemate/models/payment_method_model.dart';
import 'package:cinemate/models/showtime_model.dart';
import 'package:cinemate/views/booking/payment_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  group('PaymentMethodModel Tests (PB-021)', () {
    test(
        'PaymentMethodModel should provide predefined VA, E-Wallet, and QRIS methods',
        () {
      final methods = PaymentMethodModel.predefinedMethods;

      expect(methods, isNotEmpty);

      final vaList = methods
          .where((m) => m.category == PaymentCategory.virtualAccount)
          .toList();
      expect(vaList.length, greaterThanOrEqualTo(4)); // BCA, Mandiri, BRI, BNI
      expect(vaList.any((m) => m.name.contains('BCA')), true);
      expect(vaList.any((m) => m.accountNumber != null), true);

      final eWalletList =
          methods.where((m) => m.category == PaymentCategory.eWallet).toList();
      expect(eWalletList.length,
          greaterThanOrEqualTo(4)); // GoPay, OVO, DANA, ShopeePay
      expect(eWalletList.any((m) => m.name == 'GoPay'), true);

      final qrisList =
          methods.where((m) => m.category == PaymentCategory.qris).toList();
      expect(qrisList.length, 1);
      expect(qrisList.first.name, contains('QRIS'));
    });
  });

  group('BookingOrderModel Payment Status Tests (PB-021)', () {
    final movie = MovieModel(
      id: 533535,
      title: 'Deadpool & Wolverine',
      overview: 'Wade Wilson and Logan team up.',
      voteAverage: 7.9,
      voteCount: 1500,
      genreIds: [28, 35],
      popularity: 300.0,
      releaseDate: '2024-07-24',
    );

    final cinema = CinemaModel(
      id: 'cin-1',
      name: 'Metro Cinema Senayan',
      address: 'Jl. Asia Afrika No. 8, Jakarta Selatan',
      latitude: -6.2176,
      longitude: 106.8013,
      distanceKm: 2.6,
    );

    final showtime = ShowtimeModel(
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
    );

    test(
        'Order should transition from pending to paid and record payment details',
        () {
      final pendingOrder = BookingOrderModel(
        id: 'ORD-PENDING-001',
        movie: movie,
        cinema: cinema,
        showtime: showtime,
        selectedSeats: ['C2', 'C3'],
        ticketPrice: 50000,
        serviceFeePerTicket: 3000,
        createdAt: DateTime(2026, 11, 7, 12, 0),
        status: 'pending',
      );

      expect(pendingOrder.status, 'pending');
      expect(pendingOrder.isPaid, false);
      expect(pendingOrder.isExpired, false);

      final paidTime = DateTime(2026, 11, 7, 12, 5);
      final paidOrder = pendingOrder.copyWith(
        status: 'paid',
        paymentMethod: 'BCA Virtual Account',
        paidAt: paidTime,
        paymentReference: 'PAY-20261107-1234',
      );

      expect(paidOrder.status, 'paid');
      expect(paidOrder.isPaid, true);
      expect(paidOrder.paymentMethod, 'BCA Virtual Account');
      expect(paidOrder.paymentReference, 'PAY-20261107-1234');
      expect(paidOrder.paidAt, paidTime);
    });

    test('Order should transition to expired if countdown timer runs out', () {
      final order = BookingOrderModel(
        id: 'ORD-TIMEOUT-001',
        movie: movie,
        cinema: cinema,
        showtime: showtime,
        selectedSeats: ['A1'],
        ticketPrice: 50000,
        createdAt: DateTime.now(),
        status: 'pending',
      );

      final expiredOrder = order.copyWith(status: 'expired');
      expect(expiredOrder.isExpired, true);
      expect(expiredOrder.isPaid, false);
    });

    test('Order totalAmount should account for discount correctly', () {
      final orderWithPromo = BookingOrderModel(
        id: 'ORD-PROMO-001',
        movie: movie,
        cinema: cinema,
        showtime: showtime,
        selectedSeats: ['B1', 'B2'],
        ticketPrice: 50000,
        serviceFeePerTicket: 3000,
        discountAmount: 10000,
        createdAt: DateTime.now(),
      );

      // Subtotal: 100.000, Service Fee: 6.000, Discount: 10.000 -> Total: 96.000
      expect(orderWithPromo.subtotal, 100000);
      expect(orderWithPromo.totalServiceFee, 6000);
      expect(orderWithPromo.discountAmount, 10000);
      expect(orderWithPromo.totalAmount, 96000);
      expect(orderWithPromo.formattedTotalAmount, 'Rp 96.000');
    });
  });

  group('PaymentController E-Wallet Manual Phone Tests', () {
    setUp(() => Get.reset());
    tearDown(() => Get.reset());

    test('E-Wallet phoneController starts empty for manual input', () {
      final controller = PaymentController();
      controller.onInit();

      expect(controller.phoneController.text, isEmpty);

      controller.onClose();
    });

    test('E-Wallet payment requires valid manual phone number', () {
      final controller = PaymentController();
      controller.onInit();
      controller.selectCategory(PaymentCategory.eWallet);

      // Kosong -> wajib ditolak
      expect(controller.validateEWalletPhone(), isNotNull);

      // Kurang dari 10 digit -> wajib ditolak
      controller.phoneController.text = '0812345';
      expect(controller.validateEWalletPhone(), isNotNull);

      // Input manual valid -> diterima
      controller.phoneController.text = '081398765432';
      expect(controller.validateEWalletPhone(), isNull);

      // Virtual Account tidak memerlukan input nomor HP E-Wallet
      controller.phoneController.clear();
      controller.selectCategory(PaymentCategory.virtualAccount);
      expect(controller.validateEWalletPhone(), isNull);

      controller.onClose();
    });

    testWidgets(
        'PaymentView E-Wallet renders empty phone TextField for manual entry',
        (WidgetTester tester) async {
      final controller = Get.put(PaymentController());
      controller.selectCategory(PaymentCategory.eWallet);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: PaymentView(),
        ),
      );
      await tester.pump();

      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);
      final textField = tester.widget<TextField>(textFieldFinder);
      expect(textField.controller?.text, isEmpty);
      expect(find.text('081234567890'), findsNothing);

      await tester.enterText(textFieldFinder, '085611223344');
      expect(controller.phoneController.text, equals('085611223344'));

      await Get.delete<PaymentController>(force: true);
    });
  });
}
