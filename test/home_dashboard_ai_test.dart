// test/home_dashboard_ai_test.dart
// Unit & Widget tests untuk Epic Rekomendasi AI Dashboard & Quick Access Chatbot (PB-016, PB-017)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:cinemate/controllers/auth_controller.dart';
import 'package:cinemate/controllers/cinema_controller.dart';
import 'package:cinemate/controllers/movie_controller.dart';
import 'package:cinemate/models/mood_history_model.dart';
import 'package:cinemate/models/movie_model.dart';
import 'package:cinemate/models/user_model.dart';
import 'package:cinemate/services/storage_service.dart';
import 'package:cinemate/views/dashboard/tabs/home_tab.dart';
import 'package:cinemate/views/movie_detail/movie_detail_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late StorageService storage;

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
    await storage.clearMoodHistory();

    final authCtrl = Get.put(AuthController(storage: storage));
    authCtrl.currentUser.value = UserModel(
      id: 'usr-ai-test',
      email: 'user@cinemate.id',
      fullName: 'Nayla Cinemate',
      createdAt: DateTime.now(),
    );

    Get.put(MovieController());
    Get.put(CinemaController());
  });

  group('PB-016: Dashboard AI Recommendation Widget Tests', () {
    testWidgets('Should display invitation banner when no mood history exists',
        (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(
          home: HomeTab(),
        ),
      );
      await tester.pump();

      expect(find.text('Mood AI Recommendation'), findsOneWidget);
      expect(
        find.text(
            'Bingung mau nonton apa? Cek rekomendasi film yang sesuai dengan suasana hatimu!'),
        findsOneWidget,
      );
    });

    testWidgets(
        'Should display personalized recommendation card when mood history exists',
        (tester) async {
      // Setup mood history in storage
      final mockHistoryItem = MoodHistoryModel(
        id: 'mood-hist-1',
        moodType: 'santai',
        moodTitle: 'Santai & Rileks',
        moodEmoji: '☕',
        timestamp: DateTime.now(),
        movies: const [
          MoodHistoryItemModel(
            movieId: 101,
            title: 'Keluarga Cemara',
            matchPercentage: 96,
            aiReason:
                'Cerita hangat yang sangat pas ditonton untuk menenangkan pikiran.',
          ),
        ],
      );
      await storage.addMoodHistory(mockHistoryItem.toJson());

      await tester.pumpWidget(
        const GetMaterialApp(
          home: HomeTab(),
        ),
      );
      await tester.pump();

      expect(find.text('AI REKOMENDASI (☕ Santai & Rileks)'), findsOneWidget);
      expect(find.text('96% Cocok'), findsOneWidget);
      expect(find.text('Keluarga Cemara'), findsOneWidget);
      expect(
        find.text(
            'Cerita hangat yang sangat pas ditonton untuk menenangkan pikiran.'),
        findsOneWidget,
      );
      expect(find.text('Pesan Tiket'), findsOneWidget);
      expect(find.text('Ubah Mood'), findsOneWidget);
    });
  });

  group('PB-017: Quick Access Chatbot FAB & MovieDetail Tests', () {
    testWidgets('HomeTab should feature floating action button for CineBot',
        (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(
          home: HomeTab(),
        ),
      );
      await tester.pump();

      expect(find.text('Tanya CineBot'), findsOneWidget);
      expect(find.byIcon(Icons.smart_toy_rounded), findsOneWidget);
    });

    testWidgets('MovieDetailView should contain quick Tanya CineBot card',
        (tester) async {
      const sampleMovie = MovieModel(
        id: 202,
        title: 'Interstellar Odyssey',
        overview: 'Perjalanan luar angkasa melintasi lubang cacing.',
        posterPath: '/sample.jpg',
        backdropPath: '/sample-bg.jpg',
        releaseDate: '2026-05-10',
        voteAverage: 8.9,
        voteCount: 350,
        genreIds: [878, 12],
        popularity: 120.0,
      );

      await tester.pumpWidget(
        const GetMaterialApp(
          home: MovieDetailView(movieParam: sampleMovie),
        ),
      );
      await tester.pump();

      expect(find.text('Tanya Asisten CineBot'), findsOneWidget);
      expect(find.text('Tanya AI'), findsOneWidget);
    });
  });
}
