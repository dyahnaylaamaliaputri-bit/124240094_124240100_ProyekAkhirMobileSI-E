// lib/views/mood/advanced_profiling_view.dart
// Halaman Profiling Mood Lanjutan & Rekomendasi LLM Engine (PB-036, PB-037, PB-038)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/mood_controller.dart';
import '../../models/advanced_recommendation_model.dart';
import '../../models/movie_model.dart';
import '../../routes/app_routes.dart';
import '../../utils/app_colors.dart';

class AdvancedProfilingView extends StatefulWidget {
  const AdvancedProfilingView({super.key});

  @override
  State<AdvancedProfilingView> createState() => _AdvancedProfilingViewState();
}

class _AdvancedProfilingViewState extends State<AdvancedProfilingView> {
  late final MoodController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<MoodController>()
        ? Get.find<MoodController>()
        : Get.put(MoodController());

    // Otomatis jalankan jika hasil belum ada
    if (controller.advancedResults.isEmpty) {
      controller.runAdvancedProfiling();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 18,
          ),
          onPressed: () => Get.back(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.psychology_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'PROFILING AI LANJUTAN',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIntroBanner(),
            const SizedBox(height: 20),

            // Form Kriteria (PB-037)
            _buildSectionHeader('1. Suasana Hati (Mood)'),
            const SizedBox(height: 8),
            _buildMoodSelector(),

            const SizedBox(height: 20),
            _buildSectionHeader('2. Teman Menonton (Companion)'),
            const SizedBox(height: 8),
            _buildCompanionSelector(),

            const SizedBox(height: 20),
            _buildSectionHeader('3. Durasi Tontonan Ideal'),
            const SizedBox(height: 8),
            _buildDurationSelector(),

            const SizedBox(height: 20),
            _buildSectionHeader('4. Batas Anggaran Tiket (Budget Limit)'),
            const SizedBox(height: 8),
            _buildBudgetSelector(),

            const SizedBox(height: 24),
            _buildSubmitButton(),

            const SizedBox(height: 32),
            _buildResultsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C0F4D), Color(0xFF140728)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF8E2DE2).withValues(alpha: 0.5),
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.auto_awesome, color: AppColors.gold, size: 28),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Multi-Criteria AI Profiling (PB-036 s.d. PB-038)',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Sistem AI memadukan suasana hati, teman menonton, preferensi durasi, dan anggaran untuk kurasi tontonan paling tepat.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.gold,
        fontSize: 13,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildMoodSelector() {
    return Obx(() {
      final current = controller.selectedMood.value;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: controller.allMoods.map((mood) {
            final isSelected = mood.type == current.type;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text('${mood.emoji} ${mood.title}'),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surface,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                onSelected: (_) => controller.selectMood(mood),
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  Widget _buildCompanionSelector() {
    return Obx(() {
      final current = controller.selectedCompanion.value;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: MoodController.availableCompanions.map((comp) {
          final isSelected = comp == current;
          return ChoiceChip(
            label: Text(comp),
            selected: isSelected,
            selectedColor: const Color(0xFF8E2DE2),
            backgroundColor: AppColors.surface,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
            onSelected: (_) => controller.setCompanion(comp),
          );
        }).toList(),
      );
    });
  }

  Widget _buildDurationSelector() {
    return Obx(() {
      final current = controller.selectedDuration.value;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: MoodController.availableDurations.map((dur) {
          final isSelected = dur == current;
          return ChoiceChip(
            label: Text(dur),
            selected: isSelected,
            selectedColor: AppColors.primaryLight,
            backgroundColor: AppColors.surface,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
            onSelected: (_) => controller.setDuration(dur),
          );
        }).toList(),
      );
    });
  }

  Widget _buildBudgetSelector() {
    return Obx(() {
      final current = controller.selectedBudget.value;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: MoodController.availableBudgets.map((b) {
          final isSelected = b == current;
          return ChoiceChip(
            label: Text(
                'Rp ${b.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}'),
            selected: isSelected,
            selectedColor: AppColors.gold,
            backgroundColor: AppColors.surface,
            labelStyle: TextStyle(
              color: isSelected ? Colors.black : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
            onSelected: (_) => controller.setBudget(b),
          );
        }).toList(),
      );
    });
  }

  Widget _buildSubmitButton() {
    return Obx(() {
      final loading = controller.isProfilingLoading.value;
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: loading ? null : () => controller.runAdvancedProfiling(),
          icon: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          label: Text(
            loading
                ? 'Menganalisis dengan LLM...'
                : 'Dapatkan Rekomendasi AI Cerdas',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8E2DE2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildResultsSection() {
    return Obx(() {
      if (controller.isProfilingLoading.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Column(
              children: [
                CircularProgressIndicator(color: AppColors.gold),
                SizedBox(height: 12),
                Text(
                  'Menyelaraskan mood & preferensi Anda...',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        );
      }

      final results = controller.advancedResults;
      if (results.isEmpty) {
        return const Center(
          child: Text(
            'Belum ada rekomendasi. Tekan tombol analisis di atas.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.recommend_rounded,
                  color: AppColors.gold, size: 22),
              const SizedBox(width: 8),
              const Text(
                'HASIL REKOMENDASI TERBAIK',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Text(
                '${results.length} Pilihan',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: results.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final item = results[index];
              return _buildResultCard(item);
            },
          ),
        ],
      );
    });
  }

  Widget _buildResultCard(AdvancedRecommendationResult item) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF8E2DE2).withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Match Score + Companion Tag
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00B09B), Color(0xFF96C93D)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${item.matchScore}% Match',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    item.companionFit,
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Title & Genres
          Text(
            item.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${item.genres.join(' • ')} | ${item.durationMinutes} Menit | ~Rp ${item.estimatedPrice}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 12),

          // AI Reasoning Card (PB-038)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF8E2DE2).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome,
                    color: Color(0xFFB18CFF), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.reasoning,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Action Button: Direct Booking (PB-038)
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () {
                final movie = MovieModel(
                  id: item.movieId,
                  title: item.title,
                  overview: item.overview,
                  posterPath: item.posterPath,
                  backdropPath: item.posterPath,
                  releaseDate: '2026-01-01',
                  voteAverage: item.matchScore / 10.0,
                  voteCount: 150,
                  genreIds: const [18],
                  popularity: 80.0,
                );
                Get.toNamed(Routes.bookByMovie, arguments: movie);
              },
              icon: const Icon(Icons.confirmation_number_rounded, size: 16),
              label: const Text(
                'Pesan Tiket Sekarang',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
