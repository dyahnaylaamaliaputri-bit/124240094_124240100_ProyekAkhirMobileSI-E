// test/loyalty_gamification_test.dart
// Unit tests untuk Gamifikasi Badge Loyalitas, Kartu Watch Party, & Linimasa AI (PB-064, PB-064B, PB-065)

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:cinemate/controllers/auth_controller.dart';
import 'package:cinemate/controllers/profile_controller.dart';
import 'package:cinemate/models/loyalty_badge_model.dart';
import 'package:cinemate/models/mood_history_model.dart';
import 'package:cinemate/models/user_model.dart';
import 'package:cinemate/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late StorageService storage;
  late ProfileController profileCtrl;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (methodCall) async => tempDir.path,
    );
  });

  tearDownAll(() {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  setUp(() async {
    Get.reset();
    storage = StorageService();

    storage.themeMode = 'dark';
    storage.biometricEnabled = false;
    storage.avatarPath = null;
    await storage.saveFavoriteGenres(['Action', 'Sci-Fi', 'Drama']);
    await storage.clearMoodHistory();

    final authCtrl = Get.put(AuthController(storage: storage));
    authCtrl.currentUser.value = UserModel(
      id: 'usr-loyalty-test',
      email: 'gamer@cinemate.id',
      fullName: 'Gamer Cinephile',
      phone: '081234567890',
      createdAt: DateTime.now(),
    );

    profileCtrl = ProfileController(storage: storage);
    Get.put(profileCtrl);
  });

  tearDown(() {
    Get.reset();
  });

  group('PB-064: Model Badge Loyalitas & Gamifikasi Penonton', () {
    test('LoyaltyBadgeModel menginisialisasi properti dengan tepat', () {
      const badge = LoyaltyBadgeModel(
        id: 'test_badge',
        title: 'Badge Uji Coba',
        description: 'Deskripsi uji coba',
        icon: '⭐',
        isUnlocked: true,
        progress: 1.0,
        progressLabel: 'Tercapai',
      );

      expect(badge.id, 'test_badge');
      expect(badge.title, 'Badge Uji Coba');
      expect(badge.description, 'Deskripsi uji coba');
      expect(badge.icon, '⭐');
      expect(badge.isUnlocked, isTrue);
      expect(badge.progress, 1.0);
      expect(badge.progressLabel, 'Tercapai');
    });

    test('LoyaltyBadgeModel copyWith dapat mengubah status terkunci/terbuka',
        () {
      const initial = LoyaltyBadgeModel(
        id: 'b1',
        title: 'Badge 1',
        description: 'Desc',
        icon: '🎟️',
        isUnlocked: false,
        progress: 0.5,
        progressLabel: '1/2',
      );

      final updated = initial.copyWith(
        isUnlocked: true,
        progress: 1.0,
        progressLabel: 'Tercapai',
      );

      expect(updated.id, 'b1');
      expect(updated.isUnlocked, isTrue);
      expect(updated.progress, 1.0);
      expect(updated.progressLabel, 'Tercapai');
    });

    test('Evaluasi badge terbuka saat watchedCount mencapai milestone tertentu',
        () {
      // Kondisi awal (watchedCount = 0)
      profileCtrl.watchedCount.value = 0;
      profileCtrl.fnbOrderCount.value = 0;
      profileCtrl.moodHistory.clear();
      profileCtrl.favoriteGenres.assignAll(['Action']);

      var badges = profileCtrl.loyaltyBadges;
      final firstTicketBadge = badges.firstWhere((b) => b.id == 'first_ticket');
      final silverBadge = badges.firstWhere((b) => b.id == 'silver_cinephile');
      final goldBadge = badges.firstWhere((b) => b.id == 'gold_vip');
      final maestroBadge = badges.firstWhere((b) => b.id == 'cinema_maestro');

      expect(firstTicketBadge.isUnlocked, isFalse);
      expect(silverBadge.isUnlocked, isFalse);
      expect(goldBadge.isUnlocked, isFalse);
      expect(maestroBadge.isUnlocked, isFalse);

      // 1 tiket ditonton
      profileCtrl.watchedCount.value = 1;
      badges = profileCtrl.loyaltyBadges;
      expect(
          badges.firstWhere((b) => b.id == 'first_ticket').isUnlocked, isTrue);
      expect(badges.firstWhere((b) => b.id == 'silver_cinephile').isUnlocked,
          isFalse);

      // 3 tiket ditonton (Silver)
      profileCtrl.watchedCount.value = 3;
      badges = profileCtrl.loyaltyBadges;
      expect(badges.firstWhere((b) => b.id == 'silver_cinephile').isUnlocked,
          isTrue);
      expect(badges.firstWhere((b) => b.id == 'gold_vip').isUnlocked, isFalse);

      // 6 tiket ditonton (Gold)
      profileCtrl.watchedCount.value = 6;
      badges = profileCtrl.loyaltyBadges;
      expect(badges.firstWhere((b) => b.id == 'gold_vip').isUnlocked, isTrue);
      expect(badges.firstWhere((b) => b.id == 'cinema_maestro').isUnlocked,
          isFalse);

      // 10 tiket ditonton (Platinum Cinema Maestro)
      profileCtrl.watchedCount.value = 10;
      badges = profileCtrl.loyaltyBadges;
      expect(badges.firstWhere((b) => b.id == 'cinema_maestro').isUnlocked,
          isTrue);
    });

    test('Evaluasi badge Penyelam Genre berdasarkan jumlah genre favorit', () {
      profileCtrl.favoriteGenres.assignAll(['Action', 'Drama']);
      var badges = profileCtrl.loyaltyBadges;
      expect(badges.firstWhere((b) => b.id == 'genre_explorer').isUnlocked,
          isFalse);

      profileCtrl.favoriteGenres.assignAll(['Action', 'Drama', 'Comedy']);
      badges = profileCtrl.loyaltyBadges;
      expect(badges.firstWhere((b) => b.id == 'genre_explorer').isUnlocked,
          isTrue);
    });

    test('Evaluasi badge Master Mood AI & Snack Connoisseur', () {
      profileCtrl.moodHistory.clear();
      profileCtrl.fnbOrderCount.value = 0;

      var badges = profileCtrl.loyaltyBadges;
      expect(badges.firstWhere((b) => b.id == 'ai_cine_match').isUnlocked,
          isFalse);
      expect(badges.firstWhere((b) => b.id == 'snack_connoisseur').isUnlocked,
          isFalse);

      // Menambahkan riwayat mood
      profileCtrl.moodHistory.add(
        MoodHistoryModel(
          id: 'mood-1',
          moodType: 'happy',
          moodTitle: 'Gembira',
          moodEmoji: '😄',
          timestamp: DateTime.now(),
          movies: [],
        ),
      );
      profileCtrl.fnbOrderCount.value = 1;

      badges = profileCtrl.loyaltyBadges;
      expect(
          badges.firstWhere((b) => b.id == 'ai_cine_match').isUnlocked, isTrue);
      expect(badges.firstWhere((b) => b.id == 'snack_connoisseur').isUnlocked,
          isTrue);
    });

    test('Kalkulasi genreDistribution membagi persentase secara proporsional',
        () {
      profileCtrl.favoriteGenres
          .assignAll(['Action', 'Sci-Fi', 'Drama', 'Horror']);
      final dist = profileCtrl.genreDistribution;

      expect(dist.length, 4);
      expect(dist['Action'], 25.0);
      expect(dist['Sci-Fi'], 25.0);
      expect(dist['Drama'], 25.0);
      expect(dist['Horror'], 25.0);
    });

    test('genreDistribution mengembalikan default proporsi jika favorit kosong',
        () {
      profileCtrl.favoriteGenres.clear();
      final dist = profileCtrl.genreDistribution;

      expect(dist.isNotEmpty, isTrue);
      expect(dist.containsKey('Action'), isTrue);
      expect(dist.containsKey('Drama'), isTrue);
      expect(dist.containsKey('Sci-Fi'), isTrue);
    });
  });

  group('PB-064B: Kartu Undangan Nonton Bareng (Watch Party Invite)', () {
    test(
        'formatWatchPartyMessage menghasilkan teks undangan lengkap dengan emoji & rincian',
        () {
      final message = ProfileController.formatWatchPartyMessage(
        movieTitle: 'Interstellar',
        cinemaName: 'Cinemate Grand Indonesia XXI',
        showTime: '19:30',
        inviteNote: 'Kuy nobar akhir pekan seru!',
      );

      expect(
          message, contains('UNDANGAN NONTON BARENG (WATCH PARTY) CINEMATE'));
      expect(message, contains('*Interstellar*'));
      expect(message, contains('Cinemate Grand Indonesia XXI'));
      expect(message, contains('19:30 WIB'));
      expect(message, contains('Kuy nobar akhir pekan seru!'));
      expect(message, contains('Cinemate'));
    });

    test(
        'formatWatchPartyMessage menangani parameter opsional dengan fallback default',
        () {
      final message = ProfileController.formatWatchPartyMessage();

      expect(
          message, contains('UNDANGAN NONTON BARENG (WATCH PARTY) CINEMATE'));
      expect(message, contains('Seru-seruan bareng di bioskop pilihan!'));
      expect(
          message,
          contains(
              'Yuk nobar bareng, pesan tiket dan snack di Cinemate sekarang!'));
    });

    test('shareWatchPartyInvite sukses dieksekusi dengan fallback Clipboard',
        () async {
      // Mock clipboard handler
      String? copiedString;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        SystemChannels.platform,
        (methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            final args = methodCall.arguments as Map<dynamic, dynamic>?;
            copiedString = args?['text'] as String?;
            return null;
          }
          return null;
        },
      );

      final result = await profileCtrl.shareWatchPartyInvite(
        movieTitle: 'Spider-Man: Beyond the Spider-Verse',
        cinemaName: 'Cinemate Mall Central Park',
        showTime: '20:00',
      );

      expect(result, isTrue);
      expect(copiedString, contains('Spider-Man: Beyond the Spider-Verse'));
    });
  });

  group('PB-065: Linimasa Riwayat Profiling AI & Poster URL', () {
    test(
        'MoodHistoryItemModel posterUrl mengembalikan URL lengkap atau fallback',
        () {
      const item1 = MoodHistoryItemModel(
        movieId: 101,
        title: 'Inception',
        matchPercentage: 96,
        posterPath: '/inception_poster.jpg',
      );
      expect(item1.posterUrl,
          'https://image.tmdb.org/t/p/w500/inception_poster.jpg');

      const item2 = MoodHistoryItemModel(
        movieId: 102,
        title: 'Local Film',
        matchPercentage: 88,
        posterPath: 'https://cdn.cinemate.id/posters/film.jpg',
      );
      expect(item2.posterUrl, 'https://cdn.cinemate.id/posters/film.jpg');

      const item3 = MoodHistoryItemModel(
        movieId: 103,
        title: 'No Poster Film',
        matchPercentage: 80,
        posterPath: null,
      );
      expect(item3.posterUrl, isEmpty);
    });

    test('Merekam dan menghapus riwayat profiling AI dengan benar', () async {
      profileCtrl.moodHistory.clear();
      await storage.clearMoodHistory();

      final record1 = MoodHistoryModel(
        id: 'rec-001',
        moodType: 'touching',
        moodTitle: 'Haru & Menyentuh',
        moodEmoji: '🥺',
        timestamp: DateTime.now(),
        movies: const [
          MoodHistoryItemModel(
            movieId: 201,
            title: 'Miracle in Cell No. 7',
            matchPercentage: 98,
          ),
        ],
      );

      await profileCtrl.recordMoodProfiling(record1);

      expect(profileCtrl.moodHistory.length, 1);
      expect(profileCtrl.moodHistory.first.moodTitle, 'Haru & Menyentuh');

      // Hapus satu entri
      await profileCtrl.removeMoodHistoryItem('rec-001');
      expect(profileCtrl.moodHistory.isEmpty, isTrue);
    });

    test('Membersihkan seluruh riwayat profiling AI sekaligus', () async {
      final r1 = MoodHistoryModel(
        id: 'r1',
        moodType: 'thrilling',
        moodTitle: 'Tegang & Adrenalin',
        moodEmoji: '⚡',
        timestamp: DateTime.now(),
        movies: const [],
      );
      final r2 = MoodHistoryModel(
        id: 'r2',
        moodType: 'relaxed',
        moodTitle: 'Santai & Ringan',
        moodEmoji: '☕',
        timestamp: DateTime.now(),
        movies: const [],
      );

      await profileCtrl.recordMoodProfiling(r1);
      await profileCtrl.recordMoodProfiling(r2);
      expect(profileCtrl.moodHistory.length, 2);

      await profileCtrl.clearAllMoodHistory();
      expect(profileCtrl.moodHistory.isEmpty, isTrue);
    });
  });
}
