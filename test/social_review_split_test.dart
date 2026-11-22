// test/social_review_split_test.dart
// Unit tests untuk Epic Social Cinema & Nobar Interaktif (PB 27: PB-080, PB-081, PB-082)

import 'package:flutter_test/flutter_test.dart';
import 'package:cinemate/models/review_model.dart';
import 'package:cinemate/services/review_service.dart';
import 'package:cinemate/services/split_bill_service.dart';
import 'package:cinemate/views/booking/widgets/nobar_share_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SplitBillService splitBillService;
  late ReviewService reviewService;

  setUp(() {
    splitBillService = SplitBillService();
    reviewService = ReviewService();
  });

  // ══════════════════════════════════════════════════════════════════════════
  // PB-080: Split Bill & Patungan Pembayaran Tiket Bioskop
  // ══════════════════════════════════════════════════════════════════════════

  group('PB-080: Split Bill Tiket Bioskop', () {
    test(
        'createSplitBill menghitung pembagian rata per partisipan dengan benar',
        () {
      final bill = splitBillService.createSplitBill(
        bookingCode: 'CNM-SPLIT01',
        movieTitle: 'Avatar 3',
        totalAmount: 120000,
        participantNames: ['Alice', 'Bob', 'Charlie'],
        seatLabels: ['D1', 'D2', 'D3'],
      );

      expect(bill.totalParticipants, equals(3));
      expect(bill.amountPerPerson, equals(40000));
      expect(bill.totalAmount, equals(120000));
      expect(bill.participants.length, equals(3));
      expect(bill.participants[0].name, equals('Alice'));
      expect(bill.participants[0].seat, equals('D1'));
      expect(bill.participants[0].isPaid, isTrue); // Pemesan otomatis paid
      expect(bill.participants[1].isPaid, isFalse);
    });

    test(
        'isFullyPaid mengembalikan true hanya jika semua partisipan sudah lunas',
        () async {
      final bill = splitBillService.createSplitBill(
        bookingCode: 'CNM-SPLIT02',
        movieTitle: 'Batman',
        totalAmount: 100000,
        participantNames: ['Dyah', 'Nayla'],
      );

      expect(bill.isFullyPaid, isFalse);
      expect(bill.paidCount, equals(1));
      expect(bill.remainingAmount, equals(50000));

      final updated = await splitBillService.markParticipantPaid(
        billId: bill.id,
        participantId: 'p-1',
        isPaid: true,
      );

      expect(updated, isNotNull);
      expect(updated!.isFullyPaid, isTrue);
      expect(updated.paidCount, equals(2));
      expect(updated.remainingAmount, equals(0));
    });

    test('createSplitBill melempar ArgumentError jika partisipan kosong', () {
      expect(
        () => splitBillService.createSplitBill(
          bookingCode: 'CNM-ERR',
          movieTitle: 'Test',
          totalAmount: 50000,
          participantNames: [],
        ),
        throwsArgumentError,
      );
    });

    test(
        'shareMessage memuat rincian film, kode booking, dan nominal per orang',
        () {
      final bill = splitBillService.createSplitBill(
        bookingCode: 'CNM-SPLIT03',
        movieTitle: 'Oppenheimer',
        totalAmount: 150000,
        participantNames: ['User1', 'User2', 'User3'],
      );

      final msg = bill.shareMessage;
      expect(msg.contains('Oppenheimer'), isTrue);
      expect(msg.contains('CNM-SPLIT03'), isTrue);
      expect(msg.contains('50000'), isTrue);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // PB-081: Kartu Undangan Nobar Digital & Format Pesan Share
  // ══════════════════════════════════════════════════════════════════════════

  group('PB-081: Undangan Nobar Digital & Share', () {
    test('formatInvitationMessage menghasilkan teks undangan sinematik lengkap',
        () {
      final message = NobarShareHelper.formatInvitationMessage(
        movieTitle: 'Interstellar Re-Release',
        cinemaName: 'CGV Grand Indonesia',
        studio: 'IMAX 3D',
        showDate: '2026-12-25',
        showTime: '19:30',
        seats: ['F7', 'F8'],
        bookingCode: 'CNM-NOBAR99',
      );

      expect(message.contains('Interstellar Re-Release'), isTrue);
      expect(message.contains('CGV Grand Indonesia'), isTrue);
      expect(message.contains('IMAX 3D'), isTrue);
      expect(message.contains('F7, F8'), isTrue);
      expect(message.contains('CNM-NOBAR99'), isTrue);
      expect(message.contains('19:30 WIB'), isTrue);
    });

    test('formatInvitationMessage bekerja baik tanpa parameter opsional', () {
      final message = NobarShareHelper.formatInvitationMessage(
        movieTitle: 'Spirited Away',
        cinemaName: 'Cinepolis Plaza',
        showDate: '2026-11-30',
        showTime: '14:00',
      );

      expect(message.contains('Spirited Away'), isTrue);
      expect(message.contains('Cinepolis Plaza'), isTrue);
      expect(message.contains('14:00 WIB'), isTrue);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // PB-082: Rating Bintang 1-5 & Ulasan Komunitas Pengguna
  // ══════════════════════════════════════════════════════════════════════════

  group('PB-082: Rating & Ulasan Komunitas Pengguna', () {
    test('addReview menyimpan ulasan baru dengan rating valid', () async {
      final review = await reviewService.addReview(
        movieId: 550,
        movieTitle: 'Fight Club',
        userId: 'usr-tester-1',
        userName: 'Budi Santoso',
        rating: 4.8,
        reviewText: 'Plot twist legendaris dan visualnya sangat memikat!',
        tags: ['Plot Twist', 'Akting Mantap'],
      );

      expect(review.movieId, equals(550));
      expect(review.rating, equals(4.8));
      expect(review.reviewText, contains('Plot twist legendaris'));
      expect(review.isVerifiedAudience, isTrue);
      expect(review.tags, contains('Plot Twist'));
    });

    test('addReview membatasi nilai rating dalam batas aman 1.0 s.d. 5.0',
        () async {
      final reviewOver = await reviewService.addReview(
        movieId: 777,
        movieTitle: 'High Movie',
        userId: 'usr-1',
        userName: 'User High',
        rating: 7.5, // Di atas 5.0
        reviewText: 'Keren banget',
      );
      expect(reviewOver.rating, equals(5.0));

      final reviewUnder = await reviewService.addReview(
        movieId: 778,
        movieTitle: 'Low Movie',
        userId: 'usr-2',
        userName: 'User Low',
        rating: -2.0, // Di bawah 1.0
        reviewText: 'Kurang suka',
      );
      expect(reviewUnder.rating, equals(1.0));
    });

    test(
        'getAverageRating menghitung rata-rata skor bintang film secara presisi',
        () async {
      final avg = reviewService.getAverageRating(550);
      expect(avg, greaterThanOrEqualTo(1.0));
      expect(avg, lessThanOrEqualTo(5.0));
    });

    test('markHelpful menambah jumlah upvote helpful ulasan', () async {
      final reviews = reviewService.getReviewsForMovie(550);
      expect(reviews.isNotEmpty, isTrue);

      final firstId = reviews.first.id;
      final initialHelpful = reviews.first.helpfulCount;

      final updated = await reviewService.markHelpful(550, firstId);
      expect(updated, isNotNull);
      expect(updated!.helpfulCount, equals(initialHelpful + 1));
    });

    test('ReviewModel serialization toJson dan fromJson bekerja simetris', () {
      final original = ReviewModel(
        id: 'rev-test-json',
        movieId: 101,
        movieTitle: 'Sample Movie',
        userId: 'u1',
        userName: 'Test User',
        rating: 4.5,
        reviewText: 'Review sample',
        createdAt: DateTime(2026, 11, 20),
        helpfulCount: 5,
        tags: ['Action'],
      );

      final json = original.toJson();
      final reconstructed = ReviewModel.fromJson(json);

      expect(reconstructed.id, equals(original.id));
      expect(reconstructed.movieId, equals(original.movieId));
      expect(reconstructed.rating, equals(original.rating));
      expect(reconstructed.reviewText, equals(original.reviewText));
    });
  });
}
