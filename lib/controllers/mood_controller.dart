// lib/controllers/mood_controller.dart
// Controller untuk modul rekomendasi film berbasis Mood AI (PB-031, PB-032, PB-033)

import 'package:get/get.dart';
import '../models/mood_history_model.dart';
import '../models/mood_model.dart';
import '../models/movie_model.dart';
import '../models/advanced_recommendation_model.dart';
import '../routes/app_routes.dart';
import '../services/llm_service.dart';
import '../services/mood_service.dart';
import '../services/storage_service.dart';
import 'profile_controller.dart';

class MoodController extends GetxController {
  final MoodRecommendationService _moodService;
  final LlmService _llmService;

  MoodController({
    MoodRecommendationService? moodService,
    LlmService? llmService,
  })  : _moodService = moodService ?? MoodRecommendationService(),
        _llmService = llmService ?? LlmServiceImpl();

  /// Daftar seluruh kategori emosi yang tersedia
  final List<MoodDefinition> allMoods = MoodDefinition.allMoods;

  /// Mood yang sedang dipilih oleh pengguna
  final Rx<MoodDefinition> selectedMood =
      Rx<MoodDefinition>(MoodDefinition.allMoods.first);

  /// Daftar rekomendasi film yang dihasilkan oleh AI
  final recommendations = <MoodRecommendationItem>[].obs;

  /// Status loading rekomendasi
  final isLoading = false.obs;

  /// Pesan kesalahan jika terjadi kendala
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    if (recommendations.isEmpty) {
      loadRecommendations();
    }
  }

  /// Memilih kategori mood baru dan memperbarui rekomendasi film secara reaktif
  Future<void> selectMood(MoodDefinition mood,
      {bool forceRefresh = false}) async {
    if (!forceRefresh &&
        selectedMood.value.type == mood.type &&
        recommendations.isNotEmpty &&
        !isLoading.value) {
      return;
    }
    selectedMood.value = mood;
    await loadRecommendations(forceRefresh: forceRefresh);
  }

  /// Filter pengurutan rekomendasi (PB-032: Mood-to-Genre Discovery Engine)
  final selectedSortBy = 'popularity.desc'.obs;

  void setSortBy(String sortBy) {
    if (selectedSortBy.value == sortBy) return;
    selectedSortBy.value = sortBy;
    loadRecommendations(forceRefresh: true);
  }

  /// Memuat rekomendasi film dari service (TMDB Discovery + Fallback Offline)
  Future<void> loadRecommendations({bool forceRefresh = false}) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final items = await _moodService.getRecommendations(
        selectedMood.value.type,
        forceRefresh: forceRefresh,
        sortBy: selectedSortBy.value,
      );
      recommendations.assignAll(items);
      if (items.isNotEmpty) {
        _recordMoodHistory(items);
      }
    } catch (e) {
      errorMessage.value = 'Gagal memuat rekomendasi: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// Membuka alur pemesanan tiket bioskop langsung untuk film yang direkomendasikan
  void bookMovie(MovieModel movie) {
    Get.toNamed(Routes.bookByMovie, arguments: movie);
  }

  /// Membuka halaman detail film
  void viewMovieDetail(MovieModel movie) {
    Get.toNamed(Routes.movieDetail, arguments: movie);
  }

  /// Menyimpan hasil profiling mood ke riwayat AI (PB-065)
  void _recordMoodHistory(List<MoodRecommendationItem> items) {
    try {
      final historyItem = MoodHistoryModel(
        id: 'mood-${DateTime.now().millisecondsSinceEpoch}',
        moodType: selectedMood.value.type.name,
        moodTitle: selectedMood.value.title,
        moodEmoji: selectedMood.value.emoji,
        timestamp: DateTime.now(),
        movies: items
            .take(5)
            .map((item) => MoodHistoryItemModel(
                  movieId: item.movie.id,
                  title: item.movie.title,
                  posterPath: item.movie.posterPath,
                  matchPercentage: item.matchPercentage,
                  aiReason: item.aiReason,
                ))
            .toList(),
      );

      if (Get.isRegistered<ProfileController>()) {
        Get.find<ProfileController>().recordMoodProfiling(historyItem);
      } else {
        StorageService().addMoodHistory(historyItem.toJson());
      }
    } catch (_) {}
  }

  // =========================================================================
  // PB-036, PB-037, PB-038: PROFILING MOOD LANJUTAN & LLM ENGINE
  // =========================================================================

  final selectedCompanion = 'Sendiri 👤'.obs;
  final selectedDuration = '90 - 120 menit (Standar)'.obs;
  final selectedBudget = 50000.obs;

  final advancedResults = <AdvancedRecommendationResult>[].obs;
  final isProfilingLoading = false.obs;

  static const List<String> availableCompanions = [
    'Sendiri 👤',
    'Pasangan 💑',
    'Keluarga 👨‍👩‍👧‍👦',
    'Teman-teman 👥',
  ];

  static const List<String> availableDurations = [
    '< 90 menit (Ringkas)',
    '90 - 120 menit (Standar)',
    '> 120 menit (Epik)',
  ];

  static const List<int> availableBudgets = [
    35000,
    50000,
    75000,
    100000,
  ];

  void setCompanion(String companion) => selectedCompanion.value = companion;
  void setDuration(String duration) => selectedDuration.value = duration;
  void setBudget(int budget) => selectedBudget.value = budget;

  /// Menjalankan analisis profiling multi-kriteria melalui LLM Engine (PB-036, PB-037)
  Future<void> runAdvancedProfiling() async {
    isProfilingLoading.value = true;
    try {
      final results = await _llmService.getRecommendations(
        mood: selectedMood.value.title,
        companion: selectedCompanion.value,
        duration: selectedDuration.value,
        maxBudget: selectedBudget.value,
      );
      advancedResults.assignAll(results);

      // Simpan riwayat rekomendasi AI ke storage lokal untuk sinkronisasi (PB-038, PB-065)
      if (results.isNotEmpty) {
        final historyItem = MoodHistoryModel(
          id: 'adv-mood-${DateTime.now().millisecondsSinceEpoch}',
          moodType: selectedMood.value.type.name,
          moodTitle: selectedMood.value.title,
          moodEmoji: selectedMood.value.emoji,
          timestamp: DateTime.now(),
          movies: results
              .map((r) => MoodHistoryItemModel(
                    movieId: r.movieId,
                    title: r.title,
                    posterPath: r.posterPath,
                    matchPercentage: r.matchScore,
                    aiReason: r.reasoning,
                  ))
              .toList(),
        );

        if (Get.isRegistered<ProfileController>()) {
          Get.find<ProfileController>().recordMoodProfiling(historyItem);
        } else {
          StorageService().addMoodHistory(historyItem.toJson());
        }
      }
    } finally {
      isProfilingLoading.value = false;
    }
  }
}
