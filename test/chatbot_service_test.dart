// test/chatbot_service_test.dart
// Unit test untuk asisten chatbot AI Cinemate (PB-039 s.d. PB-041)

import 'dart:io';
import 'package:cinemate/models/chat_message_model.dart';
import 'package:cinemate/services/chatbot_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  late Directory tempDir;
  final service = ChatbotService();

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('cinemate_chatbot_test_');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('PB-039: Chatbot Message Parsing & Contextual Responses Tests', () {
    test('ChatMessageModel serialization roundtrip', () {
      final msg = ChatMessageModel(
        id: 'msg-1',
        text: 'Halo CineBot',
        sender: 'user',
        timestamp: DateTime(2026, 11, 15, 10, 0),
        suggestedPrompts: ['Jadwal Hari Ini', 'Bioskop Terdekat'],
      );

      final json = msg.toJson();
      expect(json['id'], equals('msg-1'));
      expect(json['sender'], equals('user'));
      expect(json['is_error'], isFalse);

      final fromJson = ChatMessageModel.fromJson(json);
      expect(fromJson.text, equals('Halo CineBot'));
      expect(fromJson.suggestedPrompts.length, equals(2));
      expect(fromJson.isUser, isTrue);
      expect(fromJson.isBot, isFalse);
    });

    test(
        'processUserMessage should respond with schedule information when asked about jadwal',
        () async {
      final response = await service.processUserMessage(
        'Bisa lihat jadwal film hari ini?',
        history: [],
      );

      expect(response.isBot, isTrue);
      expect(response.isError, isFalse);
      expect(response.text.toLowerCase(), contains('jadwal'));
      expect(response.text, contains('WIB'));
      expect(response.suggestedPrompts, isNotEmpty);
    });

    test(
        'processUserMessage should respond with cinema locations when asked about bioskop',
        () async {
      final response = await service.processUserMessage(
        'Bioskop terdekat di mana ya?',
        history: [],
      );

      expect(response.isBot, isTrue);
      expect(response.text.toLowerCase(), contains('bioskop'));
      expect(response.text, contains('Cinemate'));
      expect(response.suggestedPrompts, isNotEmpty);
    });

    test(
        'processUserMessage should recommend popcorn and drinks when asked about F&B',
        () async {
      final response = await service.processUserMessage(
        'Mau pesan popcorn dan minuman',
        history: [],
      );

      expect(response.isBot, isTrue);
      expect(response.text.toLowerCase(), contains('popcorn'));
      expect(response.text, contains('Counter'));
    });

    test(
        'processUserMessage should explain mood recommendations when asked about suasana hati',
        () async {
      final response = await service.processUserMessage(
        'Lagi bosan nih, ada rekomendasi film?',
        history: [],
      );

      expect(response.isBot, isTrue);
      expect(response.text.toLowerCase(), contains('mood'));
      expect(response.text, contains('MATCH'));
    });
  });

  group('PB-040: Chat History Persistence in Hive Tests', () {
    test(
        'saveChatHistory, getChatHistory and clearChatHistory should work offline',
        () async {
      final messages = [
        ChatMessageModel(
          id: 'test-1',
          text: 'Pesan tes 1',
          sender: 'user',
          timestamp: DateTime.now(),
        ),
        ChatMessageModel(
          id: 'test-2',
          text: 'Jawaban bot 1',
          sender: 'bot',
          timestamp: DateTime.now(),
        ),
      ];

      await service.saveChatHistory(messages);
      final loaded = await service.getChatHistory();
      expect(loaded.length, equals(2));
      expect(loaded[0].text, equals('Pesan tes 1'));
      expect(loaded[1].text, equals('Jawaban bot 1'));

      await service.clearChatHistory();
      final afterClear = await service.getChatHistory();
      expect(afterClear.isEmpty, isTrue);
    });
  });

  group('PB-041: Rate Limiting & Error Handling Tests', () {
    test(
        'Exceeding rate limit should return a friendly error message with retry prompt',
        () async {
      ChatMessageModel? lastResponse;

      // Kirim lebih dari maxRequestsPerMinute (12 request)
      for (int i = 0; i < 15; i++) {
        lastResponse = await service.processUserMessage(
          'Halo test ke-$i',
          history: [],
        );
      }

      expect(lastResponse, isNotNull);
      expect(lastResponse!.isError, isTrue);
      expect(lastResponse.text, contains('Terlalu banyak permintaan'));
      expect(lastResponse.suggestedPrompts, contains('Coba Lagi'));
    });
  });
}
