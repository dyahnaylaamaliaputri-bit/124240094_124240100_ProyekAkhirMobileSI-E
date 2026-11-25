// lib/controllers/search_controller.dart
// Controller untuk Pencarian & Filter Multi-Kriteria (SRC — PB 11 / PB-051 s.d. PB-055)
// Fitur:
// - PB-051: Pencarian Multi-Entitas (Film, Bioskop, F&B) dengan Debounce 300ms
// - PB-052: Filter Multi-Kriteria (Genre, Rating >= 7.0, Harga, Kota Bioskop)
// - PB-053: Pengurutan Hasil (Rating Tertinggi, Populer, Harga Termurah, Jarak Terdekat, Abjad)
// - PB-054: Riwayat 5 Pencarian Terakhir (GetStorage / StorageService)
// - PB-055: State Kosong, Skeleton Loading & Error Handling

import 'dart:async';
import 'package:flutter/material.dart' hide SearchController;
import 'package:get/get.dart';
import '../models/movie_model.dart';
import '../models/cinema_model.dart';
import '../models/fnb_item_model.dart';
import '../services/movie_service.dart';
import '../services/cinema_service.dart';
import '../services/fnb_service.dart';
import '../services/storage_service.dart';
import '../utils/validators.dart';
import '../routes/app_routes.dart';

enum SearchEntityType { all, movie, cinema, fnb }

class AppSearchController extends GetxController {
  final MovieService _movieService;
  final CinemaService _cinemaService;
  final FnbService _fnbService;
  final StorageService _storageService;

  AppSearchController({
    MovieService? movieService,
    CinemaService? cinemaService,
    FnbService? fnbService,
    StorageService? storageService,
  })  : _movieService = movieService ?? MovieService(),
        _cinemaService = cinemaService ?? CinemaService(),
        _fnbService = fnbService ?? FnbService(),
        _storageService = storageService ?? StorageService();

  // Search input & Debounce (PB-051)
  final searchInput = TextEditingController();
  final searchQuery = ''.obs;
  Worker? _debounceWorker;

  // Master datasets (Offline-first cache / seed)
  final allMovies = <MovieModel>[].obs;
  final allCinemas = <CinemaModel>[].obs;
  final allFnb = <FnbItemModel>[].obs;

  // Filtered results
  final filteredMovies = <MovieModel>[].obs;
  final filteredCinemas = <CinemaModel>[].obs;
  final filteredFnb = <FnbItemModel>[].obs;

  // States (PB-055)
  final isLoading = false.obs;
  final isInitialLoading = true.obs;
  final hasSearched = false.obs;
  final errorMessage = ''.obs;

  // Search History (PB-054) - Maksimal 5 riwayat pencarian
  final searchHistory = <String>[].obs;

  // Tab Entitas Aktif
  final selectedEntity = SearchEntityType.all.obs;

  @override
  void onInit() {
    super.onInit();
    loadSearchHistory();
    loadMasterData();

    // Debounce 300ms untuk input pencarian tanpa lag (PB-051)
    _debounceWorker = debounce(
      searchQuery,
      (query) {
        if (query.trim().isNotEmpty) {
          addSearchHistory(query.trim());
        }
        performSearch();
      },
      time: const Duration(milliseconds: 300),
    );
  }

  @override
  void onClose() {
    _debounceWorker?.dispose();
    searchInput.dispose();
    super.onClose();
  }

  // =========================================================================
  // 1. DATA INITIALIZATION (100% Offline-First)
  // =========================================================================

  Future<void> loadMasterData() async {
    isInitialLoading.value = true;
    errorMessage.value = '';

    try {
      // 1. Ambil data film (Now Playing & Upcoming)
      List<MovieModel> movies = [];
      try {
        final nowPlaying = await _movieService.getNowPlaying();
        final upcoming = await _movieService.getUpcoming();
        final combined = [...nowPlaying.movies, ...upcoming.movies];
        // Hilangkan duplikasi id
        final seen = <int>{};
        for (final m in combined) {
          if (seen.add(m.id)) {
            movies.add(m);
          }
        }
      } catch (_) {
        movies = List<MovieModel>.from(MovieService.mockNowPlaying);
      }
      if (movies.isEmpty) {
        movies = List<MovieModel>.from(MovieService.mockNowPlaying);
      }
      allMovies.assignAll(movies);

      // 2. Ambil data bioskop
      List<CinemaModel> cinemas = [];
      try {
        final res = await _cinemaService.getAllCinemas();
        cinemas = res.cinemas;
      } catch (_) {
        cinemas = CinemaService.seedCinemas
            .map((e) => CinemaModel.fromJson(e))
            .toList();
      }
      if (cinemas.isEmpty) {
        cinemas = CinemaService.seedCinemas
            .map((e) => CinemaModel.fromJson(e))
            .toList();
      }
      allCinemas.assignAll(cinemas);

      // 3. Ambil data F&B
      List<FnbItemModel> fnbItems = [];
      try {
        fnbItems = await _fnbService.getFnbItems();
      } catch (_) {
        fnbItems = List<FnbItemModel>.from(FnbItemModel.seedItems);
      }
      if (fnbItems.isEmpty) {
        fnbItems = List<FnbItemModel>.from(FnbItemModel.seedItems);
      }
      allFnb.assignAll(fnbItems);

      // Jika ada teks query awal, jalankan search
      if (searchQuery.value.trim().isNotEmpty) {
        performSearch();
      }
    } catch (e) {
      errorMessage.value = 'Gagal memuat data: $e';
    } finally {
      isInitialLoading.value = false;
    }
  }

  // =========================================================================
  // 2. SEARCH & DEBOUNCE (PB-051)
  // =========================================================================

  void onQueryChanged(String query) {
    searchQuery.value = query;
    if (query.trim().isEmpty) {
      hasSearched.value = false;
      filteredMovies.clear();
      filteredCinemas.clear();
      filteredFnb.clear();
    }
  }

  void clearSearch() {
    searchInput.clear();
    searchQuery.value = '';
    hasSearched.value = false;
    filteredMovies.clear();
    filteredCinemas.clear();
    filteredFnb.clear();
  }

  // =========================================================================
  // 3. FILTERING & SORTING ENGINE (PB-051, PB-052, PB-053)
  // =========================================================================

  void performSearch() {
    // Sanitasi input pencarian dari potensi serangan skrip/injeksi (PB-074)
    final query =
        Validators.sanitizeSearchQuery(searchQuery.value).toLowerCase();
    final hasQuery = query.isNotEmpty;

    // Jika tidak ada query, kosongkan hasil
    if (!hasQuery) {
      hasSearched.value = false;
      filteredMovies.clear();
      filteredCinemas.clear();
      filteredFnb.clear();
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';
    hasSearched.value = true;

    try {
      final entity = selectedEntity.value;

      // ── Pencarian Film ────────────────────────────────────────────────────
      List<MovieModel> movies = [];
      if (entity == SearchEntityType.all || entity == SearchEntityType.movie) {
        movies = allMovies.where((m) {
          final matchTitle = m.title.toLowerCase().contains(query);
          final matchOverview = m.overview.toLowerCase().contains(query);
          final matchGenre =
              m.genreNames.any((g) => g.toLowerCase().contains(query));
          return matchTitle || matchOverview || matchGenre;
        }).toList();
      }

      // ── Pencarian Bioskop ─────────────────────────────────────────────────
      List<CinemaModel> cinemas = [];
      if (entity == SearchEntityType.all || entity == SearchEntityType.cinema) {
        cinemas = allCinemas.where((c) {
          final matchName = c.name.toLowerCase().contains(query);
          final matchCity = c.city.toLowerCase().contains(query);
          final matchAddress = c.address.toLowerCase().contains(query);
          return matchName || matchCity || matchAddress;
        }).toList();
      }

      // ── Pencarian F&B ─────────────────────────────────────────────────────
      List<FnbItemModel> fnb = [];
      if (entity == SearchEntityType.all || entity == SearchEntityType.fnb) {
        fnb = allFnb.where((f) {
          final matchName = f.name.toLowerCase().contains(query);
          final matchDesc = f.description.toLowerCase().contains(query);
          final matchCategory = f.category.toLowerCase().contains(query);
          return matchName || matchDesc || matchCategory;
        }).toList();
      }

      filteredMovies.assignAll(movies);
      filteredCinemas.assignAll(cinemas);
      filteredFnb.assignAll(fnb);
    } catch (e) {
      errorMessage.value = 'Terjadi kesalahan saat mencari: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // =========================================================================
  // 4. FILTER SETTERS & ACTIONS (PB-052, PB-053)
  // =========================================================================

  void setEntity(SearchEntityType type) {
    if (selectedEntity.value == type) return;
    selectedEntity.value = type;
    performSearch();
  }

  void resetFilters() {
    selectedEntity.value = SearchEntityType.all;
    performSearch();
  }

  int get totalResultCount =>
      filteredMovies.length + filteredCinemas.length + filteredFnb.length;

  bool get isEmptyResult =>
      !isLoading.value && hasSearched.value && totalResultCount == 0;

  // =========================================================================
  // 5. RIWAYAT PENCARIAN (PB-054) - Max 5 Items
  // =========================================================================

  void loadSearchHistory() {
    try {
      final list = _storageService.getSearchHistory();
      searchHistory.assignAll(list.take(5));
    } catch (_) {
      searchHistory.clear();
    }
  }

  void addSearchHistory(String query) {
    final clean = query.trim();
    if (clean.isEmpty) return;

    searchHistory.remove(clean);
    searchHistory.insert(0, clean);
    if (searchHistory.length > 5) {
      searchHistory.value = searchHistory.sublist(0, 5);
    }
    _storageService.saveSearchHistory(searchHistory.toList());
  }

  void removeHistoryItem(String query) {
    searchHistory.remove(query);
    _storageService.saveSearchHistory(searchHistory.toList());
  }

  void clearAllHistory() {
    searchHistory.clear();
    _storageService.saveSearchHistory([]);
  }

  void selectHistoryItem(String query) {
    searchInput.text = query;
    searchQuery.value = query;
    addSearchHistory(query);
    performSearch();
  }

  // =========================================================================
  // 6. NAVIGATION ACTIONS
  // =========================================================================

  void openMovieDetail(MovieModel movie) {
    Get.toNamed(Routes.movieDetail, arguments: movie);
  }

  void bookMovie(MovieModel movie) {
    Get.toNamed(Routes.bookByMovie, arguments: movie);
  }

  void openCinema(CinemaModel cinema) {
    Get.toNamed(Routes.bookByCinema, arguments: cinema);
  }
}

/// Typedef untuk kompatibilitas jika modul lain mengimpor dengan nama SearchController
typedef SearchController = AppSearchController;
