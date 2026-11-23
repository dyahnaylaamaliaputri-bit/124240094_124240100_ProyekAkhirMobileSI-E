// lib/services/supabase_service.dart
// Singleton Supabase client
// Referensi: PB-002, PB-003, NFR-004
//
// Jika Supabase di-pause atau tidak dapat dihubungi:
//   - initialize() akan melempar exception yang di-catch di main.dart
//   - _initialized akan tetap false
//   - Setiap akses ke client akan melempar SocketException
//   - auth_service.dart akan mendeteksi ini dan beralih ke mode lokal

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/constants.dart';

class SupabaseService {
  SupabaseService._internal();
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;

  static bool _initialized = false;

  /// Inisialisasi Supabase dari .env atau default constant
  static Future<void> initialize() async {
    final rawUrl =
        dotenv.env['SUPABASE_URL'] ?? AppConstants.defaultSupabaseUrl;
    // Bersihkan path trailing /rest/v1/ jika tercantum agar SDK Supabase bekerja normal
    final url = rawUrl
        .replaceAll(RegExp(r'/rest/v1/?$'), '')
        .replaceAll(RegExp(r'/+$'), '');
    final anonKey =
        dotenv.env['SUPABASE_ANON_KEY'] ?? AppConstants.defaultSupabaseAnonKey;

    try {
      await Supabase.initialize(
        url: url,
        publishableKey: anonKey,
      );
      _initialized = true;
      debugPrint('[SupabaseService] ✅ Supabase berhasil diinisialisasi.');
    } catch (e) {
      _initialized = false;
      debugPrint('[SupabaseService] ⚠️ Supabase gagal diinisialisasi: $e');
      rethrow;
    }
  }

  /// Apakah Supabase berhasil diinisialisasi?
  static bool get isInitialized => _initialized;

  /// Akses langsung ke Supabase client.
  /// Melempar SocketException jika Supabase tidak tersedia (di-pause/offline).
  SupabaseClient get client {
    if (!_initialized) {
      throw const SocketException(
        'Supabase tidak tersedia (project paused atau offline). '
        'Mode lokal aktif.',
      );
    }
    return Supabase.instance.client;
  }
}
