// test/fnb_integration_lifecycle_test.dart
// Unit Test untuk PB-032 (Bundling F&B Diskon Rp 10.000), PB-033 (Pemesanan F&B Mandiri), & PB-035 (Stepper Status & Estimasi)

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:cinemate/models/booking_order_model.dart';
import 'package:cinemate/models/cinema_model.dart';
import 'package:cinemate/models/fnb_order_model.dart';
import 'package:cinemate/models/movie_model.dart';
import 'package:cinemate/models/showtime_model.dart';
import 'package:cinemate/services/fnb_service.dart';
import 'package:cinemate/controllers/order_summary_controller.dart';
import 'package:cinemate/controllers/fnb_controller.dart';

void main() {
  late Directory tempDir;
  late FnbService fnbService;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = Directory.systemTemp.createTempSync('cinemate_pb021_fnb_test_');
    Hive.init(tempDir.path);
    fnbService = FnbService();
  });

  tearDownAll(() async {
    try {
      await Hive.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  setUp(() async {
    final boxFnb = await Hive.openBox(FnbService.boxFnbCache);
    await boxFnb.clear();
    final boxOrders = await Hive.openBox(FnbService.boxFnbOrders);
    await boxOrders.clear();
  });

  BookingOrderModel createSampleOrder(
      {List<FnbOrderItemModel> fnbItems = const []}) {
    return BookingOrderModel(
      id: 'ORD-TEST-001',
      movie: MovieModel(
        id: 1,
        title: 'Interstellar',
        overview: 'Perjalanan luar angkasa melintasi wormhole.',
        voteAverage: 8.6,
        voteCount: 30000,
        genreIds: [12, 18, 878],
        popularity: 150.0,
      ),
      cinema: CinemaModel(
        id: 'cin-1',
        name: 'Grand Indonesia IMAX',
        address: 'Jl. M.H. Thamrin No. 1, Jakarta',
        latitude: -6.1950,
        longitude: 106.8210,
      ),
      showtime: ShowtimeModel(
        id: 'st-01',
        cinemaId: 'cin-1',
        movieId: 1,
        movieTitle: 'Interstellar',
        showDate: '2026-11-20',
        showTime: '19:30',
        hallName: 'IMAX Theater',
        experience: 'IMAX with Laser',
        price: 75000,
        totalSeats: 120,
        availableSeats: 90,
      ),
      selectedSeats: ['F10', 'F11'],
      ticketPrice: 75000,
      serviceFeePerTicket: 3000,
      fnbItems: fnbItems,
      createdAt: DateTime.now(),
    );
  }

  group(
      'PB-032: Langkah Opsional Tambah Makanan Sebelum Checkout (Bundling F&B)',
      () {
    test('snackBundleOptions has valid combo items with Rp 10.000 discount',
        () {
      final bundles = OrderSummaryController.snackBundleOptions;
      expect(bundles.isNotEmpty, isTrue);

      for (final bundle in bundles) {
        expect(bundle['discount'], 10000);
        final original = bundle['originalPrice'] as int;
        final discounted = bundle['bundlePrice'] as int;
        expect(discounted, original - 10000);
        expect(bundle['name'], isNotEmpty);
        expect(bundle['emoji'], isNotEmpty);
      }
    });

    test('toggleSnackBundle successfully adds combo to order and updates total',
        () {
      final baseOrder = createSampleOrder();
      final controller = OrderSummaryController();
      controller.order.value = baseOrder;

      // Harga tiket: 2 x 75.000 = 150.000
      // Biaya layanan: 2 x 3.000 = 6.000
      // Total awal tanpa F&B: 156.000
      expect(controller.finalTotalAmount, 156000);

      final bundle = OrderSummaryController.snackBundleOptions.first;
      // bundlePrice = 35.000 (diskon 10rb dari 45rb)
      controller.toggleSnackBundle(bundle);

      expect(controller.isBundleSelected(bundle['id'] as String), isTrue);
      expect(controller.order.value.fnbItems.length, 1);
      expect(controller.order.value.fnbTotal, 35000);
      // Total akhir: 156.000 + 35.000 = 191.000
      expect(controller.finalTotalAmount, 191000);
      expect(controller.order.value.fnbItems.first.note,
          contains('Diskon bundling Rp 10.000'));
    });

    test('toggleSnackBundle removes combo when tapped again', () {
      final baseOrder = createSampleOrder();
      final controller = OrderSummaryController();
      controller.order.value = baseOrder;

      final bundle = OrderSummaryController.snackBundleOptions.first;
      controller.toggleSnackBundle(bundle);
      expect(controller.finalTotalAmount, 191000);

      // Tap lagi untuk membatalkan
      controller.toggleSnackBundle(bundle);
      expect(controller.isBundleSelected(bundle['id'] as String), isFalse);
      expect(controller.order.value.fnbItems.isEmpty, isTrue);
      expect(controller.order.value.fnbTotal, 0);
      expect(controller.finalTotalAmount, 156000);
    });

    test('BookingOrderModel calculates fnbTotal and totalAmount accurately',
        () {
      final items = [
        const FnbOrderItemModel(
          fnbItemId: 'it-1',
          name: 'Popcorn Caramel',
          price: 35000,
          quantity: 2,
          subtotal: 70000,
        ),
        const FnbOrderItemModel(
          fnbItemId: 'it-2',
          name: 'Coca-Cola',
          price: 15000,
          quantity: 1,
          subtotal: 15000,
        ),
      ];

      final order = createSampleOrder(fnbItems: items);
      expect(order.fnbTotal, 85000);
      // subtotal (150.000) + serviceFee (6.000) + fnbTotal (85.000) = 241.000
      expect(order.totalAmount, 241000);
      expect(order.formattedFnbTotal, 'Rp 85.000');
    });
  });

  group('PB-033: Pemesanan F&B Mandiri Tanpa Tiket Nonton', () {
    test(
        'createOrder without ticket produces valid FNB-XXXXX pickup code and counter pickup',
        () async {
      final items = [
        const FnbOrderItemModel(
          fnbItemId: 'fnb-snk-01',
          name: 'Popcorn Jumbo Caramel',
          price: 45000,
          quantity: 1,
          subtotal: 45000,
        ),
      ];

      final order = await fnbService.createOrder(
        userId: 'usr-standalone',
        cinemaId: 'cin-1',
        cinemaName: 'Grand Indonesia Concession',
        items: items,
        pickupMethod: 'counter',
        paymentMethod: 'QRIS',
      );

      expect(order.id, startsWith('ORD-FNB-'));
      expect(RegExp(r'^FNB-\d{5}$').hasMatch(order.pickupCode), isTrue);
      expect(order.status, 'processing');
      expect(order.pickupMethod, 'counter');
      expect(order.studioNumber, isNull);
      expect(order.seatNumber, isNull);
      expect(order.subtotal, 45000);
      expect(order.serviceFee, 2000);
      expect(order.totalPrice, 47000);
      expect(order.pickupMethodLabel, contains('Ambil di Counter Concession'));
      expect(order.qrPayload, contains('CINEMATE_FNB:${order.pickupCode}'));

      // Verifikasi tersimpan di Hive orders
      final savedOrders =
          await fnbService.getUserOrders(userId: 'usr-standalone');
      expect(savedOrders.length, 1);
      expect(savedOrders.first.pickupCode, order.pickupCode);
    });

    test(
        'submitOrder in FnbController with counter pickup succeeds without studio/seat',
        () async {
      final controller = FnbController(service: fnbService);
      await controller.fetchFnbCatalog();
      await controller.loadCinemas();

      expect(controller.items.isNotEmpty, isTrue);
      final item = controller.items.first;

      controller.addToCart(item);
      controller.pickupMethod.value = 'counter';
      controller.studioNumber.value = '';
      controller.seatNumber.value = '';

      final submitted = await controller.submitOrder();

      expect(submitted, isNotNull);
      expect(submitted!.pickupCode, startsWith('FNB-'));
      expect(submitted.status, 'processing');
      expect(controller.cart.isEmpty,
          isTrue); // Keranjang direset setelah checkout
      expect(controller.userOrders.isNotEmpty, isTrue);
      expect(controller.userOrders.first.pickupCode, submitted.pickupCode);
    });
  });

  group('PB-035: Stepper Pelacakan Status & Estimasi Penyiapan', () {
    test(
        'FnbOrderModel calculates estimatedPrepMinutes and label based on item quantity',
        () {
      final items = [
        const FnbOrderItemModel(
          fnbItemId: 'it-1',
          name: 'Burger Beef',
          price: 50000,
          quantity: 2,
          subtotal: 100000,
        ),
        const FnbOrderItemModel(
          fnbItemId: 'it-2',
          name: 'Iced Lemon Tea',
          price: 15000,
          quantity: 1,
          subtotal: 15000,
        ),
      ];

      final orderProcessing = FnbOrderModel(
        id: 'ord-1',
        userId: 'u1',
        cinemaId: 'c1',
        cinemaName: 'Cinema',
        pickupCode: 'FNB-12345',
        status: 'processing',
        subtotal: 115000,
        totalPrice: 117000,
        paymentMethod: 'QRIS',
        createdAt: DateTime.now(),
        items: items,
      );

      // total item quantity = 2 + 1 = 3
      // prep minutes = 10 + (3 * 2) = 16
      expect(orderProcessing.estimatedPrepMinutes, 16);
      expect(
          orderProcessing.estimatedTimeRemainingLabel, contains('± 16 menit'));
      expect(orderProcessing.statusLabel, contains('Sedang Disiapkan'));

      final orderReady = orderProcessing.copyWith(status: 'ready');
      expect(orderReady.estimatedTimeRemainingLabel,
          contains('Siap Diambil Sekarang'));
      expect(orderReady.statusLabel, contains('Siap Diambil'));

      final orderCompleted = orderProcessing.copyWith(status: 'completed');
      expect(orderCompleted.estimatedTimeRemainingLabel,
          contains('Telah Selesai Diterima'));
      expect(orderCompleted.statusLabel, contains('Selesai Diambil'));
    });

    test(
        'advanceOrderStatus transitions through status lifecycle: processing -> ready -> completed',
        () async {
      final items = [
        const FnbOrderItemModel(
          fnbItemId: 'it-1',
          name: 'Nachos',
          price: 30000,
          quantity: 1,
          subtotal: 30000,
        ),
      ];

      final order = await fnbService.createOrder(
        userId: 'u-stepper',
        cinemaId: 'c1',
        cinemaName: 'Cinema Concession',
        items: items,
        pickupMethod: 'counter',
        paymentMethod: 'GoPay',
      );

      final controller = FnbController(service: fnbService);
      controller.userOrders.value = [order];

      // 1. Advance to 'ready'
      await controller.advanceOrderStatus(order.id);
      expect(controller.userOrders.first.status, 'ready');

      // 2. Advance to 'completed'
      await controller.advanceOrderStatus(order.id);
      expect(controller.userOrders.first.status, 'completed');

      // 3. Reset back to 'processing'
      await controller.advanceOrderStatus(order.id);
      expect(controller.userOrders.first.status, 'processing');
    });
  });
}
