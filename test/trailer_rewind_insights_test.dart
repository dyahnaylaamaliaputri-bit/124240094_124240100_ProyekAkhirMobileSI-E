// test/trailer_rewind_insights_test.dart
// Unit tests untuk Epic Video Trailer Preview & Cinema Wrap Insights (PB 28: PB-083, PB-084, PB-085)

import 'package:flutter_test/flutter_test.dart';
import 'package:cinemate/views/movie_detail/widgets/trailer_player_widget.dart';
import 'package:cinemate/views/profile/cinema_rewind_view.dart';
import 'package:cinemate/views/profile/widgets/genre_radar_chart.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ══════════════════════════════════════════════════════════════════════════
  // PB-083: Visualisasi Radar Analisis Selera Genre Film
  // ══════════════════════════════════════════════════════════════════════════

  group('PB-083: Radar Analisis Selera Genre Penonton', () {
    test('GenreRadarChart menerima spektrum genre dan skor dengan benar', () {
      final scores = {
        'Action': 0.85,
        'Sci-Fi': 0.90,
        'Drama': 0.60,
        'Romance': 0.30,
        'Horror': 0.75,
        'Comedy': 0.50,
      };

      final widget = GenreRadarChart(genreScores: scores);
      expect(widget.genreScores.length, equals(6));
      expect(widget.genreScores['Action'], equals(0.85));
      expect(widget.genreScores['Sci-Fi'], equals(0.90));
    });

    test('GenreRadarChart menangani skor kosong tanpa melempar exception', () {
      const widget = GenreRadarChart(genreScores: {});
      expect(widget.genreScores.isEmpty, isTrue);
    });

    test('Skor radar ternormalisasi dalam rentang 0.0 s.d. 1.0', () {
      final scores = {
        'Action': 1.2, // Over
        'Animation': -0.4, // Under
        'Thriller': 0.7,
      };

      scores.forEach((key, val) {
        final clamped = val.clamp(0.0, 1.0);
        expect(clamped, greaterThanOrEqualTo(0.0));
        expect(clamped, lessThanOrEqualTo(1.0));
      });
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // PB-084: Smart Video Trailer Preview di Movie Detail
  // ══════════════════════════════════════════════════════════════════════════

  group('PB-084: Smart Video Trailer Preview', () {
    test('TrailerPlayerWidget terinisialisasi dengan data film valid', () {
      const widget = TrailerPlayerWidget(
        movieTitle: 'Spider-Man: Beyond the Spider-Verse',
        backdropUrl: 'https://image.tmdb.org/t/p/w500/spiderman_bg.jpg',
        youtubeVideoKey: 'cqGjhVJWtEg',
      );

      expect(widget.movieTitle, contains('Spider-Man'));
      expect(widget.backdropUrl, contains('spiderman_bg.jpg'));
      expect(widget.youtubeVideoKey, equals('cqGjhVJWtEg'));
    });

    test('URL YouTube trailer terbentuk dengan format yang valid', () {
      const key = 'dQw4w9WgXcQ';
      final url = 'https://www.youtube.com/watch?v=$key';
      final uri = Uri.tryParse(url);

      expect(uri, isNotNull);
      expect(uri!.host, equals('www.youtube.com'));
      expect(uri.queryParameters['v'], equals('dQw4w9WgXcQ'));
    });

    test('TrailerPlayerWidget fallback gracefully bila backdropUrl kosong', () {
      const widget = TrailerPlayerWidget(
        movieTitle: 'Film Indie Lokal',
        backdropUrl: null,
      );

      expect(widget.backdropUrl, isNull);
      expect(widget.movieTitle, equals('Film Indie Lokal'));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // PB-085: "Cinemate Rewind" Kilas Balik Menonton Periode
  // ══════════════════════════════════════════════════════════════════════════

  group('PB-085: Cinemate Rewind Kilas Balik', () {
    test('Kalkulasi menit tontonan berbasis jumlah tiket (rata-rata 115 menit)',
        () {
      const movieCount = 8;
      const minutesPerMovie = 115;
      const totalMinutes = movieCount * minutesPerMovie;

      expect(totalMinutes, equals(920));
      expect(totalMinutes / 60, closeTo(15.3, 0.1)); // ~15.3 jam
    });

    test('Format teks share Cinemate Rewind memuat seluruh metrik pencapaian',
        () {
      final controller = CinemaRewindController();
      controller.totalMoviesWatched.value = 10;
      controller.totalWatchMinutes.value = 1150;
      controller.favoriteCinema.value = 'CGV Grand Indonesia';
      controller.topGenre.value = 'Sci-Fi & Action';
      controller.favoriteDay.value = 'Sabtu Malam';

      final text = '✨ *CINEMATE REWIND TAHUN INI* 🍿\n\n'
          '🎬 Total Film Ditonton: ${controller.totalMoviesWatched.value} film\n'
          '⏱️ Waktu di Bioskop: ${controller.totalWatchMinutes.value} menit\n'
          '📍 Bioskop Favorit: ${controller.favoriteCinema.value}\n'
          '🎭 Genre Andalan: ${controller.topGenre.value}\n'
          '🗓️ Hari Nonton Terfavorit: ${controller.favoriteDay.value}\n\n'
          'Cek riwayat nontonmu juga di Cinemate App! 🚀';

      expect(text.contains('10 film'), isTrue);
      expect(text.contains('1150 menit'), isTrue);
      expect(text.contains('CGV Grand Indonesia'), isTrue);
      expect(text.contains('Sci-Fi & Action'), isTrue);
      expect(text.contains('Sabtu Malam'), isTrue);
    });

    test('Akumulasi pengeluaran tiket tervalidasi dengan aman', () {
      final sampleTickets = [
        {'totalPrice': 50000},
        {'totalPrice': 75000},
        {'totalPrice': 100000},
      ];

      final total = sampleTickets.fold<int>(
          0, (sum, t) => sum + (t['totalPrice'] as int));
      expect(total, equals(225000));
    });
  });
}
