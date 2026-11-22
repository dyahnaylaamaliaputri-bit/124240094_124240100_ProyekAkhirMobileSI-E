// test/in_theater_accessibility_test.dart
// Unit tests untuk Epic In-Theater Mode, Aksesibilitas & Ekspor Tiket (PB 30: PB-089, PB-090, PB-091)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cinemate/models/ticket_model.dart';
import 'package:cinemate/services/ticket_export_service.dart';
import 'package:cinemate/views/ticket/in_theater_mode_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  TicketModel makeSampleTicket() {
    return TicketModel(
      id: 'tkt-test-30',
      bookingCode: 'CNM-TEST30',
      userId: 'usr-30',
      showtimeId: 'st-30',
      movieId: 299534,
      movieTitle: 'Avengers: Endgame',
      cinemaId: 'CGV-01',
      cinemaName: 'CGV Paris Van Java',
      cinemaAddress: 'Jl. Sukajadi No. 137',
      hallName: 'Audi 1',
      experience: '4DX 3D',
      showDate: '2026-12-31',
      showTime: '20:00',
      seats: ['E10', 'E11'],
      totalPrice: 150000,
      qrData: 'CINEMATE:CNM-TEST30:2026-12-31:20:00:E10,E11',
      paymentMethod: 'GoPay',
      createdAt: DateTime(2026, 12, 20),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PB-089: Mode Bioskop / "In-Theater Dark Mode"
  // ══════════════════════════════════════════════════════════════════════════

  group('PB-089: In-Theater Dark Mode', () {
    testWidgets('InTheaterModeView menggunakan background Colors.black murni',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: InTheaterModeView(
            movieTitle: 'Avengers: Endgame',
            cinemaName: 'CGV PVJ',
            hallName: 'Audi 1',
            seats: ['E10', 'E11'],
            showTime: '20:00',
          ),
        ),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(Colors.black));
    });

    testWidgets(
        'Nomor kursi dan judul film tampil jelas pada layar bioskop gelap',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: InTheaterModeView(
            movieTitle: 'Dune: Part Two',
            cinemaName: 'XXI Senayan',
            hallName: 'Studio 2',
            seats: ['C4', 'C5'],
            showTime: '17:00',
          ),
        ),
      );

      expect(find.text('Dune: Part Two'), findsOneWidget);
      expect(find.text('C4  C5'), findsOneWidget);
      expect(find.text('Mulai Jam: 17:00 WIB'), findsOneWidget);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // PB-090: Aksesibilitas Pembaca Layar (Semantics) & Dynamic Text
  // ══════════════════════════════════════════════════════════════════════════

  group('PB-090: Aksesibilitas Pembaca Layar (Semantics)', () {
    testWidgets(
        'Widget InTheaterModeView memiliki label semantik yang terbaca screen reader',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: InTheaterModeView(
            movieTitle: 'Interstellar',
            cinemaName: 'CGV GI',
            hallName: 'Studio IMAX',
            seats: ['G12'],
            showTime: '21:00',
          ),
        ),
      );

      // Cari Semantics nodes
      final semantics = tester.allWidgets.whereType<Semantics>();
      expect(semantics.isNotEmpty, isTrue);

      final hasMovieHeader = semantics.any(
        (s) =>
            s.properties.label == 'Film: Interstellar' &&
            s.properties.header == true,
      );
      expect(hasMovieHeader, isTrue);

      final hasSeatInfo = semantics.any(
        (s) => s.properties.label == 'Nomor kursi Anda: G12',
      );
      expect(hasSeatInfo, isTrue);
    });

    testWidgets(
        'Layar tetap responsif tanpa crash pada skala teks besar (textScale 1.5x)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(1.5),
            ),
            child: const InTheaterModeView(
              movieTitle: 'Oppenheimer',
              cinemaName: 'CGV Grand Indonesia',
              hallName: 'Studio 1',
              seats: ['F1', 'F2', 'F3'],
              showTime: '19:00',
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Oppenheimer'), findsOneWidget);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // PB-091: Ekspor Tiket ke Berkas PDF & Sinkronisasi Kalender
  // ══════════════════════════════════════════════════════════════════════════

  group('PB-091: Ekspor Struk E-Ticket & Kalender', () {
    test(
        'generateReceiptText menghasilkan struk resmi yang memuat seluruh informasi booking',
        () {
      final ticket = makeSampleTicket();
      final receipt = TicketExportService.generateReceiptText(ticket);

      expect(receipt.contains('CINEMATE E-TICKET OFFICIAL'), isTrue);
      expect(receipt.contains('CNM-TEST30'), isTrue);
      expect(receipt.contains('Avengers: Endgame'), isTrue);
      expect(receipt.contains('CGV Paris Van Java'), isTrue);
      expect(receipt.contains('Audi 1 (4DX 3D)'), isTrue);
      expect(receipt.contains('E10, E11'), isTrue);
      expect(receipt.contains('Rp 150000'), isTrue);
      expect(receipt.contains('GoPay'), isTrue);
    });

    test(
        'generateIcsCalendarContent menghasilkan format iCalendar standar RFC 5545',
        () {
      final ics = TicketExportService.generateIcsCalendarContent(
        movieTitle: 'Avengers: Endgame',
        cinemaName: 'CGV PVJ',
        hallName: 'Audi 1',
        showDate: '2026-12-31',
        showTime: '20:00',
        bookingCode: 'CNM-TEST30',
        seats: ['E10', 'E11'],
      );

      expect(ics.startsWith('BEGIN:VCALENDAR'), isTrue);
      expect(ics.contains('SUMMARY:Nonton: Avengers: Endgame'), isTrue);
      expect(ics.contains('LOCATION:CGV PVJ, Audi 1'), isTrue);
      expect(ics.contains('DTSTART:20261231T200000'), isTrue);
      expect(ics.contains('STATUS:CONFIRMED'), isTrue);
      expect(ics.endsWith('END:VCALENDAR'), isTrue);
    });
  });
}
