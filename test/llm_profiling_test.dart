// test/llm_profiling_test.dart
// Unit tests untuk Epic Profiling Mood Lanjutan & LLM Engine (PB-036, PB-037, PB-038)

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:cinemate/controllers/mood_controller.dart';
import 'package:cinemate/models/advanced_recommendation_model.dart';
import 'package:cinemate/services/llm_service.dart';
import 'package:cinemate/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late StorageService storage;
  late LlmService llmService;

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
    llmService = LlmServiceImpl();
  });

  group('PB-036: LLM Schema Validation & Prompt Construction Tests', () {
    test(
        'validateSchema should return true for complete and valid JSON payload',
        () {
      final validJson = {
        'movie_id': 1001,
        'title': 'Petualangan Sherina 2',
        'match_score': 98,
        'reasoning': 'Film hangat dan ceria untuk keluarga.',
        'companion_fit': 'Sangat pas untuk keluarga',
      };

      expect(llmService.validateSchema(validJson), isTrue);
    });

    test(
        'validateSchema should return false when required fields are missing or wrong type',
        () {
      final missingId = {
        'title': 'No ID Movie',
        'match_score': 90,
        'reasoning': 'Valid reason',
      };
      expect(llmService.validateSchema(missingId), isFalse);

      final invalidScoreType = {
        'movie_id': 1002,
        'title': 'Invalid Score',
        'match_score': 'ninety',
        'reasoning': 'Valid reason',
      };
      expect(llmService.validateSchema(invalidScoreType), isFalse);

      final missingReason = {
        'movie_id': 1003,
        'title': 'No Reason',
        'match_score': 95,
      };
      expect(llmService.validateSchema(missingReason), isFalse);
    });

    test(
        'buildPrompt should incorporate mood, companion, duration, and budget limit',
        () {
      final prompt = llmService.buildPrompt(
        mood: 'Senang',
        companion: 'Keluarga',
        duration: '90 - 120 menit',
        maxBudget: 60000,
      );

      expect(prompt, contains('Senang'));
      expect(prompt, contains('Keluarga'));
      expect(prompt, contains('90 - 120 menit'));
      expect(prompt, contains('60000'));
      expect(prompt, contains('match_score'));
    });
  });

  group('PB-036 & PB-037: Curated Rule Engine & Multi-Criteria Matching Tests',
      () {
    test(
        'Should return family-oriented recommendations when mood is Senang and companion is Keluarga',
        () async {
      final results = await llmService.getRecommendations(
        mood: 'Senang',
        companion: 'Keluarga',
        duration: '90 - 120 menit',
        maxBudget: 50000,
      );

      expect(results.isNotEmpty, isTrue);
      expect(results.first.matchScore, inInclusiveRange(88, 99));
      expect(results.any((r) => r.genres.contains('Family')), isTrue);
    });

    test(
        'Should return romance-oriented recommendations when companion is Pasangan',
        () async {
      final results = await llmService.getRecommendations(
        mood: 'Romantis',
        companion: 'Pasangan',
        duration: '90 - 120 menit',
        maxBudget: 50000,
      );

      expect(results.isNotEmpty, isTrue);
      expect(results.first.matchScore, inInclusiveRange(88, 99));
      expect(results.any((r) => r.genres.contains('Romance')), isTrue);
    });

    test('AdvancedRecommendationResult model serialization roundtrip', () {
      const item = AdvancedRecommendationResult(
        movieId: 777,
        title: 'Film Uji Coba',
        overview: 'Overview film uji coba',
        posterPath: '/path.jpg',
        matchScore: 95,
        reasoning: 'Alasan kecocokan sangat kuat.',
        companionFit: 'Cocok bersama siapa saja',
        estimatedPrice: 45000,
        durationMinutes: 110,
        genres: ['Action', 'Thriller'],
      );

      final json = item.toJson();
      final parsed = AdvancedRecommendationResult.fromJson(json);

      expect(parsed.movieId, 777);
      expect(parsed.title, 'Film Uji Coba');
      expect(parsed.matchScore, 95);
      expect(parsed.genres, ['Action', 'Thriller']);
      expect(parsed.estimatedPrice, 45000);
    });
  });

  group('PB-037 & PB-038: MoodController Advanced Profiling Integration Tests',
      () {
    test(
        'runAdvancedProfiling should populate advancedResults and save into storage history',
        () async {
      final controller = MoodController(llmService: llmService);
      controller.setCompanion('Keluarga 👨‍👩‍👧‍👦');
      controller.setDuration('90 - 120 menit (Standar)');
      controller.setBudget(50000);

      expect(controller.advancedResults.isEmpty, isTrue);

      await controller.runAdvancedProfiling();

      expect(controller.advancedResults.isNotEmpty, isTrue);
      expect(controller.advancedResults.first.matchScore,
          inInclusiveRange(88, 99));

      // Verifikasi penyimpanan riwayat di StorageService
      final history = storage.getMoodHistory();
      expect(history.isNotEmpty, isTrue);
      expect(history.first['movies'], isNotEmpty);
      expect(history.first['movies'][0]['match_percentage'],
          inInclusiveRange(88, 99));
    });
  });
}
