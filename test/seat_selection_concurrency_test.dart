// test/seat_selection_concurrency_test.dart
// Unit tests untuk Epic Pemilihan Kursi Interaktif & Concurrency Locking (PB 19: PB-027, PB-028, PB-029)

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:cinemate/controllers/booking_seat_controller.dart';
import 'package:cinemate/models/cinema_model.dart';
import 'package:cinemate/models/movie_model.dart';
import 'package:cinemate/models/seat_lock_model.dart';
import 'package:cinemate/models/seat_model.dart';
import 'package:cinemate/models/showtime_model.dart';
import 'package:cinemate/services/seat_service.dart';
import 'package:cinemate/utils/constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late SeatService seatService;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (methodCall) async => tempDir.path,
    );

    await Hive.openBox(AppConstants.boxSeatLocks);
  });

  tearDownAll(() async {
    try {
      await Hive.close();
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  setUp(() async {
    Get.reset();
    final box = Hive.box(AppConstants.boxSeatLocks);
    await box.clear();

    seatService = SeatService(box: box);
    Get.put<SeatService>(seatService);
  });

  tearDown(() {
    Get.reset();
  });

  ShowtimeModel createShowtime({
    String id = 'st-reg-1',
    String experience = 'Regular 2D',
    int price = 50000,
  }) {
    return ShowtimeModel(
      id: id,
      cinemaId: 'cin-1',
      movieId: 101,
      movieTitle: 'Inception',
      showDate: '2026-11-20',
      showTime: '19:00',
      hallName: 'Studio 1',
      experience: experience,
      price: price,
      totalSeats: 56,
      availableSeats: 48,
    );
  }

  MovieModel createMovie() {
    return MovieModel(
      id: 101,
      title: 'Inception',
      overview: 'A thief who steals corporate secrets...',
      voteAverage: 8.8,
      voteCount: 30000,
      genreIds: [28, 878],
      popularity: 120.0,
    );
  }

  CinemaModel createCinema() {
    return CinemaModel(
      id: 'cin-1',
      name: 'Cinemate Grand Indonesia',
      address: 'Jl. M.H. Thamrin No.1, Jakarta',
      latitude: -6.1951,
      longitude: 106.8208,
    );
  }

  // =========================================================================
  // PB-027: Seat Map Interaktif Multi-Studio & Subtotal
  // =========================================================================
  group('PB-027: Seat Map Interaktif Multi-Studio & Subtotal (SET — PB 19)',
      () {
    test(
        'Regular 2D menghasilkan 7 baris (A-G) dan 8 kursi per baris (56 kursi)',
        () {
      final showtime = createShowtime(experience: 'Regular 2D');
      final controller = BookingSeatController(seatService: seatService);
      controller.showtime = showtime;
      controller.movie = createMovie();
      controller.cinema = createCinema();
      controller.onInit();

      expect(controller.rows, ['A', 'B', 'C', 'D', 'E', 'F', 'G']);
      expect(controller.seatsPerRow.value, 8);
      expect(controller.totalStudioSeats, 56);
      expect(controller.seatsMap.containsKey('A1'), isTrue);
      expect(controller.seatsMap.containsKey('G8'), isTrue);
      expect(controller.seatsMap['A1']!.type, SeatType.regular);
      expect(controller.seatsMap['A1']!.price, 50000);
    });

    test(
        'IMAX with Laser menghasilkan 10 baris (A-J) dan baris J Sweetbox premium',
        () {
      final showtime =
          createShowtime(experience: 'IMAX with Laser', price: 80000);
      final controller = BookingSeatController(seatService: seatService);
      controller.showtime = showtime;
      controller.movie = createMovie();
      controller.cinema = createCinema();
      controller.onInit();

      expect(controller.rows.length, 10);
      expect(controller.rows.contains('J'), isTrue);
      expect(controller.seatsPerRow.value, 12);
      expect(controller.totalStudioSeats, 120);

      // Baris reguler IMAX
      expect(controller.seatsMap['A1']!.type, SeatType.regular);
      expect(controller.seatsMap['A1']!.price, 80000);

      // Baris J (Sweetbox) harga premium +Rp 20.000
      expect(controller.seatsMap['J1']!.type, SeatType.sweetbox);
      expect(controller.seatsMap['J1']!.price, 100000);
    });

    test('The Premiere menghasilkan 4 baris (A-D) dan 6 kursi tipe Recliner',
        () {
      final showtime =
          createShowtime(experience: 'The Premiere', price: 150000);
      final controller = BookingSeatController(seatService: seatService);
      controller.showtime = showtime;
      controller.movie = createMovie();
      controller.cinema = createCinema();
      controller.onInit();

      expect(controller.rows, ['A', 'B', 'C', 'D']);
      expect(controller.seatsPerRow.value, 6);
      expect(controller.totalStudioSeats, 24);
      expect(controller.seatsMap['A1']!.type, SeatType.recliner);
      expect(controller.seatsMap['A1']!.price, 150000);
    });

    test('Membatasi maksimal 6 kursi per pemesanan (anti-calo)', () {
      final showtime = createShowtime();
      final controller = BookingSeatController(seatService: seatService);
      controller.showtime = showtime;
      controller.movie = createMovie();
      controller.cinema = createCinema();
      controller.onInit();

      // Pastikan kursi tersedia
      for (int i = 1; i <= 6; i++) {
        final id = 'A$i';
        controller.seatsMap[id] =
            controller.seatsMap[id]!.copyWith(status: SeatStatus.available);
        controller.toggleSeat(id);
      }
      expect(controller.selectedSeats.length, 6);

      // Mencoba memilih kursi ke-7
      final id7 = 'A7';
      controller.seatsMap[id7] =
          controller.seatsMap[id7]!.copyWith(status: SeatStatus.available);
      controller.toggleSeat(id7);

      // Tetap 6 kursi, tidak bertambah
      expect(controller.selectedSeats.length, 6);
      expect(controller.selectedSeats.contains('A7'), isFalse);
    });

    test('Kalkulasi dinamis subtotal dan selectedSeatsLabel instan', () {
      final showtime = createShowtime(price: 50000);
      final controller = BookingSeatController(seatService: seatService);
      controller.showtime = showtime;
      controller.movie = createMovie();
      controller.cinema = createCinema();
      controller.onInit();

      controller.seatsMap['B3'] =
          controller.seatsMap['B3']!.copyWith(status: SeatStatus.available);
      controller.seatsMap['B4'] =
          controller.seatsMap['B4']!.copyWith(status: SeatStatus.available);

      controller.toggleSeat('B3');
      expect(controller.subtotal, 50000);
      expect(controller.selectedSeatsLabel, 'B3');

      controller.toggleSeat('B4');
      expect(controller.subtotal, 100000);
      expect(controller.selectedSeatsLabel, 'B3, B4');

      // Batalkan B3
      controller.toggleSeat('B3');
      expect(controller.subtotal, 50000);
      expect(controller.selectedSeatsLabel, 'B4');
    });
  });

  // =========================================================================
  // PB-028: Concurrency Locking & Collision Detection
  // =========================================================================
  group('PB-028: Concurrency Locking & Collision Detection (SET — PB 19)', () {
    test('lockSeats berhasil mengunci kursi saat belum ada yang memesan',
        () async {
      final result = await seatService.lockSeats(
        showtimeId: 'st-concurrency-1',
        seatLabels: ['C3', 'C4'],
        userId: 'user-alice',
      );

      expect(result.isSuccess, isTrue);
      expect(result.lockedSeats, ['C3', 'C4']);
      expect(result.conflictingSeats, isEmpty);
      expect(result.lockedUntil, isNotNull);

      final active = await seatService.getActiveLocks('st-concurrency-1');
      expect(active.length, 2);
    });

    test(
        'Collision Detection: Menolak saat User B mencoba mengunci kursi yang dikunci User A',
        () async {
      // User A mengunci kursi C4
      await seatService.lockSeats(
        showtimeId: 'st-concurrency-2',
        seatLabels: ['C4'],
        userId: 'user-alice',
      );

      // User B mencoba mengunci kursi C4 dan C5
      final resultB = await seatService.lockSeats(
        showtimeId: 'st-concurrency-2',
        seatLabels: ['C4', 'C5'],
        userId: 'user-bob',
      );

      expect(resultB.isSuccess, isFalse);
      expect(resultB.conflictingSeats, contains('C4'));
      expect(resultB.message, contains('C4'));
      expect(resultB.message, contains('pengguna lain'));
    });

    test(
        'Isolasi Pengguna: User yang sama dapat memperbarui/mengunci kembali kursinya',
        () async {
      // User A mengunci C4
      await seatService.lockSeats(
        showtimeId: 'st-concurrency-3',
        seatLabels: ['C4'],
        userId: 'user-alice',
      );

      // User A memperbarui kunci dengan menambah C5
      final resultA2 = await seatService.lockSeats(
        showtimeId: 'st-concurrency-3',
        seatLabels: ['C4', 'C5'],
        userId: 'user-alice',
      );

      expect(resultA2.isSuccess, isTrue);
      expect(resultA2.conflictingSeats, isEmpty);
    });

    test('releaseSeats melepaskan kunci sehingga dapat dipesan pengguna lain',
        () async {
      await seatService.lockSeats(
        showtimeId: 'st-concurrency-4',
        seatLabels: ['D1'],
        userId: 'user-alice',
      );

      // Alice membatalkan / melepas D1
      final released = await seatService.releaseSeats(
        showtimeId: 'st-concurrency-4',
        seatLabels: ['D1'],
        userId: 'user-alice',
      );
      expect(released, isTrue);

      // Sekarang Bob dapat mengunci D1
      final resultBob = await seatService.lockSeats(
        showtimeId: 'st-concurrency-4',
        seatLabels: ['D1'],
        userId: 'user-bob',
      );
      expect(resultBob.isSuccess, isTrue);
    });

    test(
        'getLockedSeatLabels mengecualikan excludeUserId agar kursi selectable',
        () async {
      await seatService.lockSeats(
        showtimeId: 'st-concurrency-5',
        seatLabels: ['E1'],
        userId: 'user-alice',
      );
      await seatService.lockSeats(
        showtimeId: 'st-concurrency-5',
        seatLabels: ['E2'],
        userId: 'user-bob',
      );

      // Bagi Alice, E1 dikecualikan (ia hanya melihat E2 terkunci)
      final lockedForAlice = await seatService.getLockedSeatLabels(
        'st-concurrency-5',
        excludeUserId: 'user-alice',
      );
      expect(lockedForAlice, ['E2']);

      // Bagi Bob, E2 dikecualikan (ia hanya melihat E1 terkunci)
      final lockedForBob = await seatService.getLockedSeatLabels(
        'st-concurrency-5',
        excludeUserId: 'user-bob',
      );
      expect(lockedForBob, ['E1']);
    });

    test('Controller menolak pemilihan kursi berstatus locked', () async {
      final showtime = createShowtime();
      final controller = BookingSeatController(seatService: seatService);
      controller.showtime = showtime;
      controller.movie = createMovie();
      controller.cinema = createCinema();
      controller.onInit();

      // Simulasikan kursi F5 berstatus locked oleh pengguna lain
      controller.seatsMap['F5'] =
          controller.seatsMap['F5']!.copyWith(status: SeatStatus.locked);

      controller.toggleSeat('F5');

      expect(controller.selectedSeats.contains('F5'), isFalse);
      expect(controller.seatsMap['F5']!.status, SeatStatus.locked);
    });

    test('proceedToOrderSummary mendeteksi collision dan membatalkan checkout',
        () async {
      final showtime = createShowtime();
      final controller = BookingSeatController(seatService: seatService);
      controller.showtime = showtime;
      controller.movie = createMovie();
      controller.cinema = createCinema();
      controller.onInit();

      controller.seatsMap['B2'] =
          controller.seatsMap['B2']!.copyWith(status: SeatStatus.available);
      controller.toggleSeat('B2');

      // Tiba-tiba pengguna lain mengunci B2 sesaat sebelum checkout
      await seatService.simulateConcurrentLock(
        showtimeId: showtime.id,
        seatLabel: 'B2',
        otherUserId: 'user-charlie',
      );

      await controller.proceedToOrderSummary();

      // B2 harus dihapus dari selectedSeats dan ditandai locked
      expect(controller.selectedSeats.contains('B2'), isFalse);
      expect(controller.seatsMap['B2']!.status, SeatStatus.locked);
      expect(controller.isHoldingSeats.value, isFalse);
    });
  });

  // =========================================================================
  // PB-029: Temporary Seat Hold Timer (10 Menit)
  // =========================================================================
  group('PB-029: Temporary Seat Hold Timer (10 Menit) (SET — PB 19)', () {
    test('Default hold duration adalah 600 detik (10 menit)', () {
      expect(BookingSeatController.defaultHoldDurationSeconds, 600);
    });

    test('formattedHoldTimer memformat mm:ss dengan benar', () {
      final controller = BookingSeatController(seatService: seatService);
      controller.showtime = createShowtime();
      controller.movie = createMovie();
      controller.cinema = createCinema();

      controller.holdRemainingSeconds.value = 600;
      expect(controller.formattedHoldTimer, '10:00');

      controller.holdRemainingSeconds.value = 585;
      expect(controller.formattedHoldTimer, '09:45');

      controller.holdRemainingSeconds.value = 9;
      expect(controller.formattedHoldTimer, '00:09');

      controller.holdRemainingSeconds.value = 0;
      expect(controller.formattedHoldTimer, '00:00');
    });

    test('cleanExpiredLocks membersihkan kunci yang melewati batas waktu',
        () async {
      final box = Hive.box(AppConstants.boxSeatLocks);

      // Kunci yang sudah kedaluwarsa 5 menit lalu
      final expiredLock = SeatLockModel(
        id: 'st-exp_A1',
        showtimeId: 'st-exp',
        seatLabel: 'A1',
        userId: 'user-old',
        lockedUntil: DateTime.now().subtract(const Duration(minutes: 5)),
      );
      await box.put(expiredLock.id, expiredLock.toJson());

      // Kunci yang masih aktif 5 menit lagi
      final activeLock = SeatLockModel(
        id: 'st-exp_A2',
        showtimeId: 'st-exp',
        seatLabel: 'A2',
        userId: 'user-new',
        lockedUntil: DateTime.now().add(const Duration(minutes: 5)),
      );
      await box.put(activeLock.id, activeLock.toJson());

      expect(box.length, 2);

      final cleanedCount = await seatService.cleanExpiredLocks();
      expect(cleanedCount, 1);
      expect(box.containsKey(expiredLock.id), isFalse);
      expect(box.containsKey(activeLock.id), isTrue);
    });

    test(
        'releaseHeldSeats melepaskan kunci di storage dan mematikan hold timer',
        () async {
      final showtime = createShowtime();
      final controller = BookingSeatController(seatService: seatService);
      controller.showtime = showtime;
      controller.movie = createMovie();
      controller.cinema = createCinema();
      controller.onInit();

      controller.seatsMap['C1'] =
          controller.seatsMap['C1']!.copyWith(status: SeatStatus.available);
      controller.toggleSeat('C1');

      await seatService.lockSeats(
        showtimeId: showtime.id,
        seatLabels: ['C1'],
        userId: controller.currentUserId,
      );
      controller.startHoldTimer();

      expect(controller.isHoldingSeats.value, isTrue);

      await controller.releaseHeldSeats();

      expect(controller.isHoldingSeats.value, isFalse);
      final active = await seatService.getActiveLocks(showtime.id);
      expect(active.isEmpty, isTrue);
    });
  });
}
