// lib/services/movie_service.dart
// Service untuk memanggil Public API katalog film TVmaze dengan Hive Cache & TTL 6 jam (PB-012, PB-013)
// Referensi: SRS §3.1, PB-012, PB-013, Modul V & VI

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/movie_model.dart';
import 'http_service.dart';
import 'storage_service.dart';

class MovieService {
  MovieService._internal();
  static final MovieService _instance = MovieService._internal();
  factory MovieService() => _instance;

  final HttpService _http = HttpService();
  final StorageService _storage = StorageService();

  String get _publicApiUrl =>
      dotenv.env['PUBLIC_MOVIE_API_URL'] ?? 'https://api.tvmaze.com';

  // =========================================================================
  // 1. NOW PLAYING dengan Hive Cache (TTL 6 jam)
  // =========================================================================

  /// Mengambil daftar film yang sedang tayang (Now Playing) dari Public API TVmaze (tanpa key).
  Future<
      ({
        List<MovieModel> movies,
        bool fromCache,
        bool isExpired,
        DateTime? timestamp
      })> getNowPlaying({
    int page = 1,
    bool forceRefresh = false,
  }) async {
    const cacheKey = 'now_playing_public_v1';

    // 1. Cek cache Hive jika tidak dipaksa refresh
    if (!forceRefresh) {
      final cached = await _storage.getCachedMovies(cacheKey);
      if (cached.data != null && !cached.isExpired && cached.data!.isNotEmpty) {
        final list = cached.data!.map((e) => MovieModel.fromJson(e)).toList();
        return (
          movies: list,
          fromCache: true,
          isExpired: false,
          timestamp: cached.timestamp
        );
      }
    }

    // 2. Fetch online dari Public API (https://api.tvmaze.com/shows?page=0) - Tanpa API Key!
    try {
      final response = await _http.get(
        '$_publicApiUrl/shows',
        queryParameters: {'page': page - 1},
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200 && response.data is List) {
        final List rawList = response.data as List;
        final list = rawList
            .whereType<Map<String, dynamic>>()
            .map((e) => MovieModel.fromTvMazeJson(e))
            .where((m) => m.posterUrl.isNotEmpty)
            .toList()
          ..sort((a, b) => b.voteAverage.compareTo(a.voteAverage));

        final topMovies = list.take(20).toList();
        if (topMovies.isNotEmpty) {
          await _storage.cacheMovies(
              cacheKey, topMovies.map((m) => m.toJson()).toList());
          return (
            movies: topMovies,
            fromCache: false,
            isExpired: false,
            timestamp: DateTime.now()
          );
        }
      }
    } catch (e) {
      debugPrint(
          '[MovieService] Error Public API Now Playing ($e), beralih ke cache Hive...');
    }

    // 3. Jika offline atau API gagal, muat dari Hive cache (meskipun TTL lewat)
    final fallback = await _storage.getCachedMovies(cacheKey);
    if (fallback.data != null && fallback.data!.isNotEmpty) {
      final list = fallback.data!.map((e) => MovieModel.fromJson(e)).toList();
      return (
        movies: list,
        fromCache: true,
        isExpired: fallback.isExpired,
        timestamp: fallback.timestamp,
      );
    }

    // 4. Jika cache Hive pertama kali masih kosong, simpan mock data dan kembalikan
    await _storage.cacheMovies(
        cacheKey, _mockNowPlaying.map((m) => m.toJson()).toList());
    return (
      movies: _mockNowPlaying,
      fromCache: true,
      isExpired: false,
      timestamp: DateTime.now(),
    );
  }

  // =========================================================================
  // 2. COMING SOON / UPCOMING dengan Hive Cache (TTL 6 jam)
  // =========================================================================

  /// Mengambil daftar film yang akan segera tayang (Coming Soon / Upcoming)
  Future<
      ({
        List<MovieModel> movies,
        bool fromCache,
        bool isExpired,
        DateTime? timestamp
      })> getUpcoming({
    int page = 1,
    bool forceRefresh = false,
  }) async {
    const cacheKey = 'upcoming_public_v1';

    // 1. Cek cache Hive jika tidak dipaksa refresh
    if (!forceRefresh) {
      final cached = await _storage.getCachedMovies(cacheKey);
      if (cached.data != null && !cached.isExpired && cached.data!.isNotEmpty) {
        final list = cached.data!.map((e) => MovieModel.fromJson(e)).toList();
        return (
          movies: list,
          fromCache: true,
          isExpired: false,
          timestamp: cached.timestamp
        );
      }
    }

    // 2. Fetch online dari Public API (https://api.tvmaze.com/shows?page=1) - Tanpa API Key!
    try {
      final response = await _http.get(
        '$_publicApiUrl/shows',
        queryParameters: {'page': page},
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200 && response.data is List) {
        final List rawList = response.data as List;
        final list = rawList
            .whereType<Map<String, dynamic>>()
            .map((e) => MovieModel.fromTvMazeJson(e))
            .where((m) => m.posterUrl.isNotEmpty)
            .toList()
          ..sort((a, b) => b.popularity.compareTo(a.popularity));

        final upcomingMovies = list.take(15).toList();
        if (upcomingMovies.isNotEmpty) {
          await _storage.cacheMovies(
              cacheKey, upcomingMovies.map((m) => m.toJson()).toList());
          return (
            movies: upcomingMovies,
            fromCache: false,
            isExpired: false,
            timestamp: DateTime.now()
          );
        }
      }
    } catch (e) {
      debugPrint(
          '[MovieService] Error Public API Upcoming ($e), beralih ke cache Hive...');
    }

    // 3. Jika offline atau API gagal, muat dari Hive cache
    final fallback = await _storage.getCachedMovies(cacheKey);
    if (fallback.data != null && fallback.data!.isNotEmpty) {
      final list = fallback.data!.map((e) => MovieModel.fromJson(e)).toList();
      return (
        movies: list,
        fromCache: true,
        isExpired: fallback.isExpired,
        timestamp: fallback.timestamp,
      );
    }

    // 4. Simpan mock data ke cache dan kembalikan
    await _storage.cacheMovies(
        cacheKey, _mockUpcoming.map((m) => m.toJson()).toList());
    return (
      movies: _mockUpcoming,
      fromCache: true,
      isExpired: false,
      timestamp: DateTime.now(),
    );
  }

  // =========================================================================
  // 3. BANNER CAROUSEL dengan Hive Cache
  // =========================================================================

  /// Mengambil film sorotan untuk banner carousel utama
  Future<({List<MovieModel> movies, bool fromCache})> getBannerMovies({
    bool forceRefresh = false,
  }) async {
    const cacheKey = 'banner_public_v1';

    if (!forceRefresh) {
      final cached = await _storage.getCachedMovies(cacheKey);
      if (cached.data != null && !cached.isExpired && cached.data!.isNotEmpty) {
        final list = cached.data!.map((e) => MovieModel.fromJson(e)).toList();
        return (movies: list, fromCache: true);
      }
    }

    final nowPlayingRes = await getNowPlaying(forceRefresh: forceRefresh);
    if (nowPlayingRes.movies.isNotEmpty) {
      final sorted = List<MovieModel>.from(nowPlayingRes.movies)
        ..sort((a, b) => b.popularity.compareTo(a.popularity));
      final topBanners = sorted.take(5).toList();

      await _storage.cacheMovies(
          cacheKey, topBanners.map((m) => m.toJson()).toList());
      return (movies: topBanners, fromCache: nowPlayingRes.fromCache);
    }

    return (movies: _mockNowPlaying.take(5).toList(), fromCache: true);
  }

  // =========================================================================
  // MOCK DATA (Fallback jika offline & cache kosong pertama kali)
  // =========================================================================

  static List<MovieModel> get mockNowPlaying => _mockNowPlaying;

  static final List<MovieModel> _mockNowPlaying = [
    const MovieModel(
      id: 693134,
      title: 'Dune: Part Two',
      overview:
          'Paul Atreides bersatu dengan Chani dan Fremen untuk membalas dendam terhadap para konspirator yang menghancurkan keluarganya.',
      posterPath: '/8b8R8l88Qje9dn9OE8PY05Nxl1X.jpg',
      backdropPath: '/xOMo8BRK7PfcJv9JCnx7s5200bm.jpg',
      releaseDate: '2024-03-01',
      voteAverage: 8.3,
      voteCount: 4500,
      genreIds: [878, 12],
      popularity: 350.5,
    ),
    const MovieModel(
      id: 533535,
      title: 'Deadpool & Wolverine',
      overview:
          'Wade Wilson yang lesu kembali beraksi saat TVA merekrutnya untuk melindungi garis waktu bersama Wolverine yang enggan.',
      posterPath: '/8cdWjvZQUExUUTzyp4t6EDMubfO.jpg',
      backdropPath: '/yDHYTjA3R0jFYba16jBB1jv8v2C.jpg',
      releaseDate: '2024-07-26',
      voteAverage: 7.9,
      voteCount: 3800,
      genreIds: [28, 35, 878],
      popularity: 420.2,
    ),
    const MovieModel(
      id: 1022789,
      title: 'Inside Out 2',
      overview:
          'Riley kini beranjak remaja dan Ruang Kendali emosinya mengalami perombakan mendadak untuk menyambut emosi-emosi baru.',
      posterPath: '/vpnVM9B6NMmQpWeZvzLvDESb2QY.jpg',
      backdropPath: '/p5ozvmdgsmbWe0H8wf4NelljhBs.jpg',
      releaseDate: '2024-06-14',
      voteAverage: 8.0,
      voteCount: 5200,
      genreIds: [16, 10751, 35],
      popularity: 380.1,
    ),
    const MovieModel(
      id: 519182,
      title: 'Despicable Me 4',
      overview:
          'Gru menghadapi musuh baru Maxime Le Mal dan pacarnya Valentina, memaksa seluruh keluarga Gru untuk melarikan diri.',
      posterPath: '/wWba3TaojhK7NdycRhoQpsG0FaH.jpg',
      backdropPath: '/lgkGYSyJsGtz6q7OpeaGTUhHbAc.jpg',
      releaseDate: '2024-07-03',
      voteAverage: 7.3,
      voteCount: 2200,
      genreIds: [16, 10751, 35],
      popularity: 290.0,
    ),
    const MovieModel(
      id: 573435,
      title: 'Bad Boys: Ride or Die',
      overview:
          'Detektif Mike Lowrey dan Marcus Burnett kembali beraksi saat kapten mereka difitnah, membuat mereka menjadi buronan.',
      posterPath: '/nP6RliHjxsz4irTKsxe8FRhKZYl.jpg',
      backdropPath: '/ga4OLm4qLxO1GyF4hk00V98G9QG.jpg',
      releaseDate: '2024-06-07',
      voteAverage: 7.6,
      voteCount: 2100,
      genreIds: [28, 80, 35],
      popularity: 260.4,
    ),
  ];

  static final List<MovieModel> _mockUpcoming = [
    const MovieModel(
      id: 558449,
      title: 'Gladiator II',
      overview:
          'Bertahun-tahun setelah menyaksikan kematian Maximus di tangan pamannya, Lucius harus memasuki Colosseum untuk memperjuangkan masa depan Roma.',
      posterPath: '/2cxhvwyEwRlysAmRH4iodkvo0z5.jpg',
      backdropPath: '/euYIwmwkmz95mnEx7vBM0MqzEDn.jpg',
      releaseDate: '2024-11-22',
      voteAverage: 8.1,
      voteCount: 890,
      genreIds: [28, 12, 18],
      popularity: 310.0,
    ),
    const MovieModel(
      id: 402431,
      title: 'Wicked',
      overview:
          'Kisah Elphaba, wanita muda berkulit hijau yang disalahpahami, dan Glinda, wanita populer penuh keistimewaan di Negeri Oz.',
      posterPath: '/2E1mvQHytPvIq2sqTIIraDbu2vx.jpg',
      backdropPath: '/uKB22E5kyQE9wf4GEZe9oMcflvg.jpg',
      releaseDate: '2024-11-27',
      voteAverage: 7.7,
      voteCount: 650,
      genreIds: [18, 14, 10402],
      popularity: 280.0,
    ),
    const MovieModel(
      id: 1241982,
      title: 'Moana 2',
      overview:
          'Moana menerima panggilan mendadak dari leluhurnya untuk berlayar ke perairan jauh Oseania dalam petualangan berbahaya.',
      posterPath: '/yh64qw9mgXBvlaWDi7Q9tpUBAvH.jpg',
      backdropPath: '/tElnmtQ6yz1PjN1kePNl8yMSb59.jpg',
      releaseDate: '2024-11-27',
      voteAverage: 7.8,
      voteCount: 710,
      genreIds: [16, 12, 10751],
      popularity: 330.0,
    ),
    const MovieModel(
      id: 933260,
      title: 'The Substance',
      overview:
          'Seorang selebritas yang menua memutuskan untuk menggunakan obat pasar gelap misterius yang dapat mereplikasi sel untuk menciptakan versi dirinya yang lebih muda.',
      posterPath: '/lqoMzCcZY59p0k8j3zIic3c0nS7.jpg',
      backdropPath: '/7h6r9WcQ3pZ1G9B3dZ2W4x5z8a9.jpg',
      releaseDate: '2024-10-31',
      voteAverage: 7.4,
      voteCount: 1400,
      genreIds: [27, 878, 18],
      popularity: 240.0,
    ),
  ];
}
