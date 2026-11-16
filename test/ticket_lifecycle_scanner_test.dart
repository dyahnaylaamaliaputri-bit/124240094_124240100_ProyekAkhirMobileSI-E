// test/ticket_lifecycle_scanner_test.dart
// Unit Test untuk PB-026 (Auto-expire Tiket Kedaluwarsa), PB-026B (QR Scanner Check-in), & PB-026C (Bagikan Tiket)

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:cinemate/models/ticket_model.dart';
import 'package:cinemate/services/storage_service.dart';
import 'package:cinemate/controllers/tickets_controller.dart';
import 'package:cinemate/controllers/ticket_detail_controller.dart';

void main() {
  late Directory tempDir;
  late StorageService storage;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = Directory.systemTemp.createTempSync('cinemate_pb026_test_');
    Hive.init(tempDir.path);
    storage = StorageService();
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
    final box = await Hive.openBox('tickets_cache');
    await box.clear();
  });

  TicketModel createSampleTicket({
    required String id,
    required String bookingCode,
    required String showDate,
    required String showTime,
    String status = 'paid',
    String movieTitle = 'Deadpool & Wolverine',
    String cinemaName = 'Metro Cinema Senayan',
    String hallName = 'Studio 1',
    List<String> seats = const ['C1', 'C2'],
  }) {
    return TicketModel(
      id: id,
      bookingCode: bookingCode,
      userId: 'usr-tester',
      showtimeId: 'st-01',
      movieId: 533535,
      movieTitle: movieTitle,
      cinemaId: 'cin-1',
      cinemaName: cinemaName,
      cinemaAddress: 'Jl. Jenderal Sudirman No. 1, Jakarta',
      hallName: hallName,
      experience: 'Regular 2D',
      showDate: showDate,
      showTime: showTime,
      seats: seats,
      totalPrice: 100000,
      qrData: 'CINEMATE:$bookingCode:$showDate:$showTime:${seats.join(',')}',
      status: status,
      paymentMethod: 'QRIS',
      paymentReference: 'PAY-12345',
      createdAt: DateTime.now(),
    );
  }

  group('PB-026: Penandaan Tiket Kedaluwarsa Otomatis (Auto Expiry)', () {
    test('autoExpirePastTickets detects past tickets and updates status to expired',
        () async {
      final pastTicket = createSampleTicket(
        id: 'tkt-past-1',
        bookingCode: 'CNM-11111',
        showDate: '2020-01-01',
        showTime: '10:00',
        status: 'paid',
      );

      final futureTicket = createSampleTicket(
        id: 'tkt-future-1',
        bookingCode: 'CNM-22222',
        showDate: '2099-12-31',
        showTime: '20:00',
        status: 'paid',
      );

      // Simpan kedua tiket ke cache
      await storage.cacheTickets([pastTicket.toJson(), futureTicket.toJson()]);

      final controller = TicketsController();
      controller.activeTickets.value = [pastTicket, futureTicket];
      controller.historyTickets.clear();

      final expiredCount = await controller.autoExpirePastTickets();

      expect(expiredCount, 1);
      expect(controller.activeTickets.length, 1);
      expect(controller.activeTickets.first.bookingCode, 'CNM-22222');
      expect(controller.historyTickets.length, 1);
      expect(controller.historyTickets.first.bookingCode, 'CNM-11111');
      expect(controller.historyTickets.first.status, 'expired');
    });

    test('autoExpirePastTickets does not expire tickets that are already used or future',
        () async {
      final futureTicket = createSampleTicket(
        id: 'tkt-future-2',
        bookingCode: 'CNM-33333',
        showDate: '2099-06-15',
        showTime: '18:00',
        status: 'paid',
      );

      final controller = TicketsController();
      controller.activeTickets.value = [futureTicket];
      controller.historyTickets.clear();

      final expiredCount = await controller.autoExpirePastTickets();
      expect(expiredCount, 0);
      expect(controller.activeTickets.length, 1);
      expect(controller.activeTickets.first.status, 'paid');
    });

    test('loadTickets automatically executes autoExpirePastTickets on load',
        () async {
      final pastTicket = createSampleTicket(
        id: 'tkt-past-2',
        bookingCode: 'CNM-44444',
        showDate: '2021-05-10',
        showTime: '13:00',
        status: 'paid',
      );

      await storage.cacheTickets([pastTicket.toJson()]);

      final controller = TicketsController();
      await controller.loadTickets();

      // Tiket lampau harus berakhir di historyTickets dengan status expired
      expect(controller.activeTickets.isEmpty, isTrue);
      expect(controller.historyTickets.length, 1);
      expect(controller.historyTickets.first.bookingCode, 'CNM-44444');
      expect(controller.historyTickets.first.status, 'expired');
    });
  });

  group('PB-026B: QR Scanner Check-in Petugas Bioskop', () {
    test('validateAndCheckInBookingCode successfully checks in an active ticket',
        () async {
      final validTicket = createSampleTicket(
        id: 'tkt-valid-1',
        bookingCode: 'CNM-55555',
        showDate: '2099-01-01',
        showTime: '15:00',
        status: 'paid',
      );

      await storage.cacheTickets([validTicket.toJson()]);

      final controller = TicketsController();
      controller.activeTickets.value = [validTicket];
      controller.historyTickets.clear();

      final result =
          await controller.validateAndCheckInBookingCode('CNM-55555');

      expect(result.success, isTrue);
      expect(result.ticket, isNotNull);
      expect(result.ticket!.status, 'used');
      expect(result.message, contains('Check-in Berhasil'));
      expect(controller.activeTickets.isEmpty, isTrue);
      expect(controller.historyTickets.length, 1);
      expect(controller.historyTickets.first.status, 'used');
    });

    test('validateAndCheckInBookingCode parses raw QR payload format',
        () async {
      final validTicket = createSampleTicket(
        id: 'tkt-valid-2',
        bookingCode: 'CNM-66666',
        showDate: '2099-01-01',
        showTime: '15:00',
        status: 'paid',
      );

      await storage.cacheTickets([validTicket.toJson()]);

      final controller = TicketsController();
      controller.activeTickets.value = [validTicket];
      controller.historyTickets.clear();

      // Format payload dari scanner kamera: CINEMATE:CNM-66666:2099-01-01:15:00:C1,C2
      final rawQr = validTicket.qrData;
      final result = await controller.validateAndCheckInBookingCode(rawQr);

      expect(result.success, isTrue);
      expect(result.ticket, isNotNull);
      expect(result.ticket!.bookingCode, 'CNM-66666');
      expect(result.ticket!.status, 'used');
    });

    test('validateAndCheckInBookingCode rejects duplicate scan for already used ticket',
        () async {
      final usedTicket = createSampleTicket(
        id: 'tkt-used-1',
        bookingCode: 'CNM-77777',
        showDate: '2099-01-01',
        showTime: '15:00',
        status: 'used',
      );

      await storage.cacheTickets([usedTicket.toJson()]);

      final controller = TicketsController();
      controller.activeTickets.clear();
      controller.historyTickets.value = [usedTicket];

      final result =
          await controller.validateAndCheckInBookingCode('CNM-77777');

      expect(result.success, isFalse);
      expect(result.message, contains('sudah pernah digunakan'));
    });

    test('validateAndCheckInBookingCode rejects expired ticket', () async {
      final expiredTicket = createSampleTicket(
        id: 'tkt-exp-1',
        bookingCode: 'CNM-88888',
        showDate: '2020-01-01',
        showTime: '12:00',
        status: 'expired',
      );

      await storage.cacheTickets([expiredTicket.toJson()]);

      final controller = TicketsController();
      controller.activeTickets.clear();
      controller.historyTickets.value = [expiredTicket];

      final result =
          await controller.validateAndCheckInBookingCode('CNM-88888');

      expect(result.success, isFalse);
      expect(result.message, contains('telah kedaluwarsa'));
    });

    test('validateAndCheckInBookingCode rejects unknown booking code',
        () async {
      final controller = TicketsController();
      controller.activeTickets.clear();
      controller.historyTickets.clear();

      final result =
          await controller.validateAndCheckInBookingCode('CNM-00000');

      expect(result.success, isFalse);
      expect(result.message, contains('tidak ditemukan'));
    });

    test('validateAndCheckInBookingCode rejects empty input', () async {
      final controller = TicketsController();
      final result = await controller.validateAndCheckInBookingCode('   ');

      expect(result.success, isFalse);
      expect(result.message, contains('tidak boleh kosong'));
    });
  });

  group('PB-026C: Fitur Bagikan Tiket & Undangan Nonton', () {
    test('formatShareMessage generates complete invitation text', () {
      final ticket = createSampleTicket(
        id: 'tkt-share-1',
        bookingCode: 'CNM-99999',
        showDate: '2026-11-20',
        showTime: '19:30',
        movieTitle: 'Interstellar',
        cinemaName: 'Grand Indonesia IMAX',
        hallName: 'IMAX Theater',
        seats: ['F10', 'F11'],
      );

      final message = TicketDetailController.formatShareMessage(ticket);

      expect(message, contains('Undangan Nonton Bareng - CINEMATE'));
      expect(message, contains('Interstellar'));
      expect(message, contains('Grand Indonesia IMAX'));
      expect(message, contains('IMAX Theater'));
      expect(message, contains('19:30 WIB'));
      expect(message, contains('F10, F11'));
      expect(message, contains('CNM-99999'));
      expect(message, contains('Pesan tiket bioskop mudah & cepat'));
    });

    test('TicketModel status labels work correctly across states', () {
      final activeTicket = createSampleTicket(
        id: 'tkt-1',
        bookingCode: 'CNM-1',
        showDate: '2099-01-01',
        showTime: '12:00',
        status: 'paid',
      );
      expect(activeTicket.isTicketActive, isTrue);
      expect(activeTicket.isTicketHistory, isFalse);

      final usedTicket = createSampleTicket(
        id: 'tkt-2',
        bookingCode: 'CNM-2',
        showDate: '2099-01-01',
        showTime: '12:00',
        status: 'used',
      );
      expect(usedTicket.isTicketActive, isFalse);
      expect(usedTicket.isTicketHistory, isTrue);
      expect(usedTicket.historyStatusLabel, 'Sudah Ditonton');

      final expiredTicket = createSampleTicket(
        id: 'tkt-3',
        bookingCode: 'CNM-3',
        showDate: '2020-01-01',
        showTime: '12:00',
        status: 'expired',
      );
      expect(expiredTicket.isTicketActive, isFalse);
      expect(expiredTicket.isTicketHistory, isTrue);
      expect(expiredTicket.historyStatusLabel, 'Selesai');
    });
  });
}
