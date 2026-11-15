// lib/controllers/chatbot_controller.dart
// Controller state management percakapan Asisten Chatbot AI Cinemate (PB-039 s.d. PB-041)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message_model.dart';
import '../services/chatbot_service.dart';

class ChatbotController extends GetxController {
  final ChatbotService _service = ChatbotService();
  final Uuid _uuid = const Uuid();

  final messages = <ChatMessageModel>[].obs;
  final isLoading = false.obs;
  final lastFailedQuery = Rxn<String>();

  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  static const List<String> initialPrompts = [
    'Ada film apa yang tayang hari ini?',
    'Rekomendasi film komedi seru',
    'Bioskop terdekat di sekitar saya',
    'Menu camilan popcorn & minuman',
  ];

  @override
  void onInit() {
    super.onInit();
    loadChatHistory().then((_) {
      final args = Get.arguments;
      if (args is Map && args['initialQuery'] is String) {
        final initial = args['initialQuery'] as String;
        if (initial.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 300), () {
            sendMessage(initial);
          });
        }
      }
    });
  }

  @override
  void onClose() {
    textController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  /// Membaca riwayat percakapan dari Hive (PB-040)
  Future<void> loadChatHistory() async {
    final history = await _service.getChatHistory();
    if (history.isNotEmpty) {
      messages.assignAll(history);
    } else {
      // Pesan selamat datang default
      messages.add(
        ChatMessageModel(
          id: _uuid.v4(),
          text:
              'Halo! Saya **CineBot**, asisten AI bioskop Cinemate Anda. 🍿\nAda yang bisa saya bantu terkait jadwal, rekomendasi film, lokasi bioskop terdekat, atau menu F&B hari ini?',
          sender: 'bot',
          timestamp: DateTime.now(),
          suggestedPrompts: initialPrompts,
        ),
      );
    }
    _scrollToBottom();
  }

  /// Mengirim pesan dari pengguna ke asisten AI (PB-039)
  Future<void> sendMessage([String? customText]) async {
    final text = (customText ?? textController.text).trim();
    if (text.isEmpty) return;

    if (customText == null) {
      textController.clear();
    }

    final userMsg = ChatMessageModel(
      id: _uuid.v4(),
      text: text,
      sender: 'user',
      timestamp: DateTime.now(),
    );

    messages.add(userMsg);
    _scrollToBottom();

    isLoading.value = true;
    lastFailedQuery.value = null;

    try {
      final botMsg = await _service.processUserMessage(
        text,
        history: messages.toList(),
      );

      messages.add(botMsg);
      if (botMsg.isError) {
        lastFailedQuery.value = text;
      }
      await _service.saveChatHistory(messages.toList());
    } catch (e) {
      final errorMsg = ChatMessageModel(
        id: _uuid.v4(),
        text:
            'Maaf, terjadi kesalahan saat memproses permintaan Anda. Silakan coba lagi.',
        sender: 'bot',
        timestamp: DateTime.now(),
        isError: true,
        suggestedPrompts: ['Coba Lagi', 'Jadwal Hari Ini'],
      );
      messages.add(errorMsg);
      lastFailedQuery.value = text;
    } finally {
      isLoading.value = false;
      _scrollToBottom();
    }
  }

  /// Mencoba kembali query terakhir yang gagal (PB-041)
  void retryLastMessage() {
    if (lastFailedQuery.value != null && lastFailedQuery.value!.isNotEmpty) {
      sendMessage(lastFailedQuery.value);
    }
  }

  /// Menghapus seluruh riwayat percakapan chat (PB-040)
  Future<void> clearHistory() async {
    await _service.clearChatHistory();
    messages.clear();
    messages.add(
      ChatMessageModel(
        id: _uuid.v4(),
        text:
            'Riwayat percakapan telah dibersihkan. Silakan tanyakan hal baru seputar film atau bioskop Cinemate!',
        sender: 'bot',
        timestamp: DateTime.now(),
        suggestedPrompts: initialPrompts,
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
