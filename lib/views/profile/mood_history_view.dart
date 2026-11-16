// lib/views/profile/mood_history_view.dart
// Layar Linimasa Riwayat AI & Komparasi Mood (PB-065)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/profile_controller.dart';
import '../../models/mood_history_model.dart';
import '../../routes/app_routes.dart';
import '../../utils/app_colors.dart';

class MoodHistoryView extends StatefulWidget {
  const MoodHistoryView({super.key});

  @override
  State<MoodHistoryView> createState() => _MoodHistoryViewState();
}

class _MoodHistoryViewState extends State<MoodHistoryView> {
  final ProfileController profileCtrl = Get.isRegistered<ProfileController>()
      ? Get.find<ProfileController>()
      : Get.put(ProfileController());

  String _selectedMoodFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    profileCtrl.loadMoodHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 18,
          ),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'LINIMASA RIWAYAT AI',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 16,
          ),
        ),
        actions: [
          Obx(() {
            if (profileCtrl.moodHistory.isEmpty) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.delete_sweep_rounded,
                  color: AppColors.primary),
              tooltip: 'Hapus Semua Riwayat',
              onPressed: () => _confirmClearAll(context),
            );
          }),
        ],
      ),
      body: Obx(() {
        final allHistory = profileCtrl.moodHistory;

        if (allHistory.isEmpty) {
          return _buildEmptyState();
        }

        final filteredHistory = _selectedMoodFilter == 'Semua'
            ? allHistory
            : allHistory
                .where((item) =>
                    item.moodTitle.toLowerCase() ==
                    _selectedMoodFilter.toLowerCase())
                .toList();

        return RefreshIndicator(
          onRefresh: () async {
            profileCtrl.loadMoodHistory();
          },
          color: AppColors.gold,
          backgroundColor: AppColors.card,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. STATISTIK KOMPARASI MOOD SUMMARY
                _buildSummaryHeader(allHistory),

                const SizedBox(height: 16),

                // 2. FILTER CHIPS MOOD
                _buildFilterChips(allHistory),

                const SizedBox(height: 16),

                // 3. DAFTAR LINIMASA RIWAYAT
                if (filteredHistory.isEmpty)
                  _buildNoFilteredResults()
                else
                  _buildTimelineList(filteredHistory),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// Ringkasan komparasi mood penonton
  Widget _buildSummaryHeader(List<MoodHistoryModel> history) {
    // Cari mood paling dominan
    final moodCounts = <String, int>{};
    for (final item in history) {
      moodCounts[item.moodTitle] = (moodCounts[item.moodTitle] ?? 0) + 1;
    }
    String topMood = '-';
    int topCount = 0;
    moodCounts.forEach((mood, count) {
      if (count > topCount) {
        topCount = count;
        topMood = mood;
      }
    });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.insights_rounded, color: AppColors.gold, size: 20),
              SizedBox(width: 8),
              Text(
                'Ringkasan Profiling AI',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryMetric(
                  label: 'Total Sesi',
                  value: '${history.length}',
                  color: AppColors.gold,
                ),
              ),
              Container(width: 1, height: 36, color: AppColors.border),
              Expanded(
                child: _buildSummaryMetric(
                  label: 'Mood Dominan',
                  value: topMood,
                  color: Colors.cyanAccent,
                ),
              ),
              Container(width: 1, height: 36, color: AppColors.border),
              Expanded(
                child: _buildSummaryMetric(
                  label: 'Rekomendasi',
                  value: '${history.fold(0, (sum, h) => sum + h.movies.length)} Film',
                  color: Colors.greenAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetric({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Filter Chips untuk memilih mood tertentu
  Widget _buildFilterChips(List<MoodHistoryModel> allHistory) {
    final uniqueMoods = <String>{'Semua'};
    for (final h in allHistory) {
      uniqueMoods.add(h.moodTitle);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: uniqueMoods.map((mood) {
          final isSelected = _selectedMoodFilter == mood;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                mood,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedMoodFilter = mood);
                }
              },
              selectedColor: AppColors.gold.withValues(alpha: 0.3),
              backgroundColor: AppColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.gold : AppColors.border,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Tampilan linimasa riwayat profiling
  Widget _buildTimelineList(List<MoodHistoryModel> history) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final item = history[index];
        return _buildTimelineCard(item);
      },
    );
  }

  Widget _buildTimelineCard(MoodHistoryModel item) {
    final dateFormatted =
        '${item.timestamp.day.toString().padLeft(2, '0')}/${item.timestamp.month.toString().padLeft(2, '0')}/${item.timestamp.year} • ${item.timestamp.hour.toString().padLeft(2, '0')}:${item.timestamp.minute.toString().padLeft(2, '0')} WIB';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card: Mood & Waktu
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Text(item.moodEmoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mood: ${item.moodTitle}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        dateFormatted,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.textSecondary, size: 18),
                  tooltip: 'Hapus Entri',
                  onPressed: () => profileCtrl.removeMoodHistoryItem(item.id),
                ),
              ],
            ),
          ),

          // Daftar Film Hasil Rekomendasi
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rekomendasi Film Sesuai Mood:',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                if (item.movies.isEmpty)
                  const Text(
                    'Tidak ada film yang disimpan.',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  )
                else
                  ...item.movies.map((movie) => _buildMovieRow(movie)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovieRow(MoodHistoryItemModel movie) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Poster / Icon
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: movie.posterUrl.isNotEmpty
                ? Image.network(
                    movie.posterUrl,
                    width: 38,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholderPoster(),
                  )
                : _buildPlaceholderPoster(),
          ),
          const SizedBox(width: 10),
          // Info Film
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${movie.matchPercentage}% Kecocokan Mood',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Tombol Cari / Pesan
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.gold, size: 14),
            tooltip: 'Cari Film',
            onPressed: () {
              Get.toNamed(Routes.search, arguments: movie.title);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderPoster() {
    return Container(
      width: 38,
      height: 52,
      color: AppColors.card,
      child: const Icon(
        Icons.movie_outlined,
        color: AppColors.textDisabled,
        size: 18,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.psychology_outlined,
                color: AppColors.gold, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Riwayat AI Mood',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gunakan fitur Rekomendasi Mood AI untuk mencari tontonan yang pas dengan suasana hatimu saat ini!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Get.toNamed(Routes.moodPicker),
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: const Text('Mulai Profiling AI'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoFilteredResults() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.filter_alt_off_rounded,
              color: AppColors.textSecondary, size: 36),
          const SizedBox(height: 8),
          Text(
            'Tidak ada riwayat untuk mood "$_selectedMoodFilter"',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context) {
    Get.defaultDialog(
      title: 'Hapus Semua Riwayat',
      titleStyle: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
      middleText:
          'Apakah Anda yakin ingin menghapus seluruh riwayat profiling AI Mood?',
      middleTextStyle: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
      ),
      backgroundColor: AppColors.card,
      textConfirm: 'Hapus Semua',
      textCancel: 'Batal',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.primary,
      cancelTextColor: AppColors.textSecondary,
      onConfirm: () async {
        await profileCtrl.clearAllMoodHistory();
        Get.back();
      },
    );
  }
}
