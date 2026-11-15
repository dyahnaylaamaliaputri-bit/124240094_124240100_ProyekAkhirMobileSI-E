// lib/services/chatbot_service.dart
// Service Asisten AI Chatbot Cinemate dengan integrasi Hive cache & rate limiting (PB-039 s.d. PB-041)
// Referensi: SRS Â§3.8 FR-043, FR-044, FR-045, PB-039, PB-040, PB-041

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message_model.dart';
import '../models/cinema_model.dart';
import '../models/fnb_item_model.dart';
import 'cinema_service.dart';

class ChatbotService {
  ChatbotService._internal();
  static final ChatbotService _instance = ChatbotService._internal();
  factory ChatbotService() => _instance;

  static const String boxChatHistory = 'chat_history';
  static const String keyMessages = 'messages_list';

  final Uuid _uuid = const Uuid();
  final CinemaService _cinemaService = CinemaService();

  // Rate limiting counter (PB-041)
  int _requestCount = 0;
  DateTime? _windowStart;
  static const int maxRequestsPerMinute = 12;

  /// Membuka Hive Box untuk riwayat percakapan chatbot (PB-040)
  Future<Box> _openBox() async {
    if (Hive.isBoxOpen(boxChatHistory)) {
      return Hive.box(boxChatHistory);
    }
    return await Hive.openBox(boxChatHistory);
  }

  /// Membaca riwayat percakapan chatbot yang tersimpan di Hive (offline-accessible)
  Future<List<ChatMessageModel>> getChatHistory() async {
    try {
      final box = await _openBox();
      final raw = box.get(keyMessages);
      if (raw != null && raw is List) {
        return raw.map((e) {
          final map = Map<String, dynamic>.from(e as Map);
          return ChatMessageModel.fromJson(map);
        }).toList();
      }
    } catch (e) {
      debugPrint('[ChatbotService] Error reading chat history: $e');
    }
    return [];
  }

  /// Menyimpan daftar percakapan ke Hive box (PB-040)
  Future<void> saveChatHistory(List<ChatMessageModel> messages) async {
    try {
      final box = await _openBox();
      final jsonList = messages.map((m) => m.toJson()).toList();
      await box.put(keyMessages, jsonList);
    } catch (e) {
      debugPrint('[ChatbotService] Error saving chat history: $e');
    }
  }

  /// Menghapus seluruh riwayat percakapan (PB-040)
  Future<void> clearChatHistory() async {
    try {
      final box = await _openBox();
      await box.delete(keyMessages);
    } catch (e) {
      debugPrint('[ChatbotService] Error clearing chat history: $e');
    }
  }

  /// Mengirim pesan pengguna dan menghasilkan respon asisten AI (PB-039, PB-041)
  Future<ChatMessageModel> processUserMessage(
    String userText, {
    required List<ChatMessageModel> history,
  }) async {
    final now = DateTime.now();

    // 1. Cek Rate Limiting (PB-041)
    if (_windowStart == null || now.difference(_windowStart!).inSeconds > 60) {
      _windowStart = now;
      _requestCount = 0;
    }
    _requestCount++;

    if (_requestCount > maxRequestsPerMinute) {
      final remainingSec = 60 - now.difference(_windowStart!).inSeconds;
      return ChatMessageModel(
        id: _uuid.v4(),
        text:
            '⚠️ Terlalu banyak permintaan dalam waktu singkat. Asisten AI sedang istirahat sejenak. Silakan tunggu $remainingSec detik sebelum bertanya kembali.',
        sender: 'bot',
        timestamp: now,
        isError: true,
        suggestedPrompts: ['Coba Lagi', 'Lihat Jadwal Bioskop', 'Menu F&B'],
      );
    }

    // Simulasi jeda berpikir AI natural (300ms - 600ms)
    await Future.delayed(const Duration(milliseconds: 400));

    // 2. Analisis Intent & Hasilkan Respon Kontekstual Cerdas (PB-039)
    final lower = userText.toLowerCase().trim();

    // Skenario A: Pertanyaan Jadwal & Jam Tayang
    if (lower.contains('jadwal') ||
        lower.contains('jam tayang') ||
        lower.contains('kapan tayang')) {
      return ChatMessageModel(
        id: _uuid.v4(),
        text:
            '🎬 **Jadwal Bioskop Hari Ini:**\nPenayangan film dimulai pukul **12:00 WIB** hingga **21:30 WIB** setiap hari di seluruh jaringan bioskop Cinemate.\n\nStudio yang tersedia:\n• **Regular 2D** (Rp 45.000 - Rp 50.000)\n• **IMAX with Laser** (Rp 75.000)\n• **The Premiere** (Rp 100.000)\n\nAnda dapat memilih film atau bioskop langsung di halaman Beranda untuk melihat kursi yang tersisa.',
        sender: 'bot',
        timestamp: now,
        suggestedPrompts: [
          'Bioskop terdekat di mana?',
          'Rekomendasi film bagus',
          'Cara pesan tiket'
        ],
      );
    }

    // Skenario B: Pertanyaan Bioskop & Lokasi
    if (lower.contains('bioskop') ||
        lower.contains('lokasi') ||
        lower.contains('tempat') ||
        lower.contains('dekat')) {
      final seedList = CinemaService.seedCinemas
          .map((e) => CinemaModel.fromJson(e))
          .toList();
      final cinemas = _cinemaService.getNearestCinemas(
        seedList,
        userLat: -6.1754,
        userLng: 106.8272,
      );

      final cinemaNames = cinemas.isNotEmpty
          ? cinemas.map((c) => '• **${c.name}** (${c.city})').join('\n')
          : '• **Cinemate Plaza** (Jakarta Pusat)\n• **Metro Cinema Senayan** (Jakarta Selatan)\n• **Cinemate Kelapa Gading** (Jakarta Utara)';

      return ChatMessageModel(
        id: _uuid.v4(),
        text:
            '📍 **Lokasi Bioskop Terdekat:**\nBerikut beberapa bioskop Cinemate pilihan di sekitar Anda:\n$cinemaNames\n\n💡 *Tips: Buka tab **Peta Bioskop** untuk melihat visualisasi peta OpenStreetMap interaktif dan petunjuk arah ke Google Maps!*',
        sender: 'bot',
        timestamp: now,
        suggestedPrompts: [
          'Buka Peta Bioskop',
          'Film yang sedang tayang',
          'Pesan Snack Popcorn'
        ],
      );
    }

    // Skenario C: Makanan, Minuman, Popcorn & F&B
    if (lower.contains('fnb') ||
        lower.contains('makanan') ||
        lower.contains('minuman') ||
        lower.contains('popcorn') ||
        lower.contains('snack')) {
      final fnbItems = FnbItemModel.seedItems.take(3).toList();
      final itemText = fnbItems
          .map((item) => '• **${item.name}** - ${item.formattedPrice}')
          .join('\n');

      return ChatMessageModel(
        id: _uuid.v4(),
        text:
            '🍿 **Katalog Makanan & Camilan Favorit Cinemate:**\n$itemText\n\nFitur spesial:\n✅ **Ambil di Counter Concession** dengan QR voucher mandiri\n✅ **Antar Langsung ke Studio & Kursi** oleh staf bioskop selagi Anda menonton!',
        sender: 'bot',
        timestamp: now,
        suggestedPrompts: [
          'Pesan Paket Combo',
          'Metode antar ke kursi',
          'Cara bayar'
        ],
      );
    }

    // Skenario D: Rekomendasi Film Berdasarkan Mood / Genre
    if (lower.contains('mood') ||
        lower.contains('rekomendasi') ||
        lower.contains('saran') ||
        lower.contains('sedih') ||
        lower.contains('senang') ||
        lower.contains('takut') ||
        lower.contains('tegang') ||
        lower.contains('bosan')) {
      return ChatMessageModel(
        id: _uuid.v4(),
        text:
            '✨ **Rekomendasi Film Cerdas Berbasis Mood AI:**\nCinemate memiliki fitur kurasi film berdasarkan suasana hati Anda:\n• **Gembira / Bosan:** Komedi & Animasi penuh tawa\n• **Tegang / Adrenalin:** Action, Thriller, & Horor mencekam\n• **Haru / Romantis:** Drama percintaan & cerita penuh emosi mendalam\n\nCoba fitur **Mood AI Picker** di Beranda untuk mendapatkan skor kecocokan personal (88% - 99% MATCH)!',
        sender: 'bot',
        timestamp: now,
        suggestedPrompts: [
          'Buka Mood Picker',
          'Film Horor Terpopuler',
          'Film Drama Terbaru'
        ],
      );
    }

    // Skenario E: Tiket, Pembayaran & E-Ticket Offline
    if (lower.contains('tiket') ||
        lower.contains('bayar') ||
        lower.contains('qris') ||
        lower.contains('transfer') ||
        lower.contains('offline')) {
      return ChatMessageModel(
        id: _uuid.v4(),
        text:
            '🎟️ **Panduan Tiket & Akses Offline:**\n1. Pilih film, bioskop, jam tayang, dan kursi favorit Anda.\n2. Lakukan simulasi pembayaran via Virtual Account (BCA, Mandiri, BRI) atau QRIS Dinamis.\n3. Tiket QR otomatis tersimpan di memori perangkat (**Hive NoSQL Cache**).\n\n📱 **Tetap bisa dibuka tanpa koneksi internet saat Anda tiba di pintu studio bioskop!**',
        sender: 'bot',
        timestamp: now,
        suggestedPrompts: [
          'Lihat Tiket Saya',
          'Pilih Bioskop Dulu',
          'Menu Makanan'
        ],
      );
    }

    // Skenario F: Sapaan & Bantuan Umum
    if (lower.contains('halo') ||
        lower.contains('hai') ||
        lower.contains('pagi') ||
        lower.contains('siang') ||
        lower.contains('malam') ||
        lower.contains('bantu')) {
      return ChatMessageModel(
        id: _uuid.v4(),
        text:
            'Halo! Saya **CineBot**, asisten AI pintar Cinemate. 🍿\nAda yang bisa saya bantu hari ini? Anda bisa menanyakan:\n• Informasi film terbaru & sinopsis\n• Jadwal bioskop & harga tiket\n• Lokasi bioskop terdekat\n• Rekomendasi film sesuai suasana hati (Mood AI)\n• Menu camilan & minuman F&B',
        sender: 'bot',
        timestamp: now,
        suggestedPrompts: [
          'Film tayang hari ini?',
          'Bioskop terdekat di Jakarta?',
          'Rekomendasi film komedi'
        ],
      );
    }

    // Skenario Default Cerdas
    return ChatMessageModel(
      id: _uuid.v4(),
      text:
          'Saya memahami Anda bertanya tentang *"$userText"*. Sebagai asisten bioskop AI Cinemate, saya dapat membantu Anda mencari jadwal tayang, bioskop terdekat, rekomendasi film sesuai mood, maupun pemesanan snack bioskop.\n\nSilakan pilih salah satu opsi cepat di bawah atau ketikkan pertanyaan lebih spesifik!',
      sender: 'bot',
      timestamp: now,
      suggestedPrompts: [
        'Jadwal bioskop hari ini',
        'Rekomendasi film sesuai mood',
        'Menu Popcorn & Minuman',
        'Lokasi bioskop terdekat'
      ],
    );
  }
}
