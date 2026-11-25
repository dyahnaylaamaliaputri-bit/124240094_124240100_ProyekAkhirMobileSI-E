// test/payment_success_sheet_test.dart
import 'package:cinemate/models/booking_order_model.dart';
import 'package:cinemate/models/cinema_model.dart';
import 'package:cinemate/models/movie_model.dart';
import 'package:cinemate/models/showtime_model.dart';
import 'package:cinemate/utils/app_theme.dart';
import 'package:cinemate/views/booking/widgets/payment_success_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'PaymentSuccessSheet renders clean anti-slop confirmation without emoji and triggers actions',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    bool wentHome = false;
    bool viewedTicket = false;

    final order = BookingOrderModel(
      id: 'ord-1',
      movie: const MovieModel(
        id: 1,
        title: 'Midnight Diner: Tokyo Stories Super Extended Edition',
        overview: 'Sinopsis film uji',
        voteAverage: 7.7,
        voteCount: 120,
        genreIds: [18],
        popularity: 380,
      ),
      cinema: const CinemaModel(
        id: 'cin-1',
        name: 'Central Park CGV Jakarta Barat Studio Premiere',
        address: 'Jl. Letjen S. Parman No. 28',
        latitude: -6.177,
        longitude: 106.791,
      ),
      showtime: const ShowtimeModel(
        id: 'st-1',
        cinemaId: 'cin-1',
        movieId: 1,
        movieTitle: 'Midnight Diner',
        showDate: '2026-11-25',
        showTime: '19:15',
        hallName: 'Studio 1',
      ),
      selectedSeats: const ['C4', 'C5'],
      ticketPrice: 50000,
      createdAt: DateTime(2026, 11, 25, 19, 0),
      status: 'paid',
      paymentMethod: 'QRIS',
      paymentReference: 'PAY-20261125-001',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: PaymentSuccessSheet(
              order: order,
              onGoHome: () => wentHome = true,
              onViewTicket: () => viewedTicket = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Pembayaran Berhasil'), findsOneWidget);
    expect(find.textContaining('🎉'), findsNothing);
    expect(find.text('PAY-20261125-001'), findsOneWidget);
    expect(find.text('C4, C5'), findsOneWidget);
    expect(find.text('QRIS'), findsOneWidget);
    expect(find.text(order.formattedTotalAmount), findsOneWidget);

    final homeSize = tester.getSize(find.widgetWithText(OutlinedButton, 'Ke Beranda'));
    final ticketSize = tester.getSize(find.text('Lihat E-Ticket'));
    expect(homeSize.height, greaterThanOrEqualTo(44));
    expect(ticketSize.height, greaterThan(0));

    await tester.tap(find.text('Ke Beranda'));
    expect(wentHome, isTrue);

    await tester.tap(find.text('Lihat E-Ticket'));
    expect(viewedTicket, isTrue);
  });
}
