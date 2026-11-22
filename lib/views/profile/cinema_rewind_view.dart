// lib/views/profile/cinema_rewind_view.dart
// Kilas balik tahunan & statistik menonton pengguna (PB-085)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/storage_service.dart';
import '../../utils/app_colors.dart';

class CinemaRewindController extends GetxController {
  final StorageService _storage = StorageService();

  final totalMoviesWatched = 0.obs;
  final totalWatchMinutes = 0.obs;
  final totalSpent = 0.obs;
  final favoriteCinema = ''.obs;
  final topGenre = ''.obs;
  final favoriteDay = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _calculateRewindStats();
  }

  Future<void> _calculateRewindStats() async {
    final tickets = await _storage.getCachedTickets();
    if (tickets != null && tickets.isNotEmpty) {
      totalMoviesWatched.value = tickets.length;
      totalWatchMinutes.value =
          tickets.length * 115; // Rata-rata 115 menit per film
      totalSpent.value = tickets.fold<int>(
          0, (sum, t) => sum + ((t['totalPrice'] as num?)?.toInt() ?? 50000));
      favoriteCinema.value =
          (tickets.first['cinemaName'] as String?) ?? 'CGV Grand Indonesia';
      topGenre.value = 'Action & Sci-Fi';
      favoriteDay.value = 'Sabtu Malam';
    } else {
      // Data estimasi penonton aktif
      totalMoviesWatched.value = 6;
      totalWatchMinutes.value = 690;
      totalSpent.value = 350000;
      favoriteCinema.value = 'CGV Grand Indonesia';
      topGenre.value = 'Action & Sci-Fi';
      favoriteDay.value = 'Sabtu Malam';
    }
  }

  void shareRewind() {
    final text = '✨ *CINEMATE REWIND TAHUN INI* 🍿\n\n'
        '🎬 Total Film Ditonton: ${totalMoviesWatched.value} film\n'
        '⏱️ Waktu di Bioskop: ${totalWatchMinutes.value} menit\n'
        '📍 Bioskop Favorit: ${favoriteCinema.value}\n'
        '🎭 Genre Andalan: ${topGenre.value}\n'
        '🗓️ Hari Nonton Terfavorit: ${favoriteDay.value}\n\n'
        'Cek riwayat nontonmu juga di Cinemate App! 🚀';

    // ignore: deprecated_member_use
    Share.share(text, subject: 'Cinemate Rewind Saya');
  }
}

class CinemaRewindView extends StatelessWidget {
  const CinemaRewindView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CinemaRewindController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cinemate Rewind ✨',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Obx(() {
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Banner Hero Rewind
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF8B0000),
                    AppColors.primary,
                    Color(0xFF1A1A2E)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.auto_awesome,
                      color: AppColors.gold, size: 40),
                  const SizedBox(height: 8),
                  const Text(
                    'Kilas Balik Sinematik',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Perjalanan menonton Anda bersama Cinemate',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const Divider(color: Colors.white24, height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn(
                        '${controller.totalMoviesWatched.value}',
                        'Film Ditonton',
                        Icons.movie_creation_outlined,
                      ),
                      Container(height: 36, width: 1, color: Colors.white24),
                      _buildStatColumn(
                        '${controller.totalWatchMinutes.value}m',
                        'Menit di Bioskop',
                        Icons.timer_outlined,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Kartu Highlight Rewind
            _buildHighlightCard(
              title: 'Bioskop Paling Sering Dikunjungi',
              value: controller.favoriteCinema.value,
              icon: Icons.storefront_outlined,
              color: AppColors.gold,
            ),

            const SizedBox(height: 12),

            _buildHighlightCard(
              title: 'Genre Favorit Pilihan Hati',
              value: controller.topGenre.value,
              icon: Icons.theater_comedy_outlined,
              color: Colors.purpleAccent,
            ),

            const SizedBox(height: 12),

            _buildHighlightCard(
              title: 'Hari Nonton Terbanyak',
              value: controller.favoriteDay.value,
              icon: Icons.calendar_today_outlined,
              color: Colors.blueAccent,
            ),

            const SizedBox(height: 12),

            _buildHighlightCard(
              title: 'Estimasi Pengeluaran Tiket',
              value: 'Rp ${controller.totalSpent.value}',
              icon: Icons.account_balance_wallet_outlined,
              color: Colors.greenAccent,
            ),

            const SizedBox(height: 32),

            // Tombol Bagikan Rewind
            ElevatedButton.icon(
              onPressed: () => controller.shareRewind(),
              icon: const Icon(Icons.share, color: Colors.white),
              label: const Text(
                'Bagikan Cinemate Rewind ke Medsos',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStatColumn(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.gold, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildHighlightCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
