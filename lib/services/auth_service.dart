// lib/services/auth_service.dart
// Custom auth di atas tabel public.users Supabase (bukan Supabase Auth bawaan)
// Referensi: PB-005, PB-006, PB-007, PB-008, R-06
//
// Strategi hashing password (karena tidak ada bcrypt):
//   salt  = random UUID
//   hash  = SHA-256(password + salt)
//   stored = "$salt:$hash"
//
// Strategi session token:
//   raw_token = UUID → disimpan di secure_storage
//   token_hash = SHA-256(raw_token) → disimpan di tabel sessions
//
// OFFLINE MODE: Jika Supabase tidak dapat dihubungi (paused/offline),
//   auth akan jatuh ke penyimpanan lokal (GetStorage) secara transparan.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/session_model.dart';
import '../utils/constants.dart';
import 'supabase_service.dart';
import 'storage_service.dart';

class AuthService {
  AuthService._internal();
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  final _supabase = SupabaseService();
  final _storage = StorageService();
  final _uuid = const Uuid();
  final _localStore = GetStorage();

  // Key prefix untuk penyimpanan lokal user
  static const String _localUsersKey = '_local_users';

  SupabaseClient get _db => _supabase.client;

  // ================================================================
  // Helper: cek apakah error terkait koneksi (Supabase paused/offline)
  // ================================================================
  bool _isConnectionError(Object e) {
    if (e is TimeoutException || e is SocketException) return true;
    final msg = e.toString().toLowerCase();
    return msg.contains('socket') ||
        msg.contains('failed host lookup') ||
        msg.contains('clientexception') ||
        msg.contains('connection refused') ||
        msg.contains('network') ||
        msg.contains('host lookup') ||
        msg.contains('timeout') ||
        msg.contains('timed out') ||
        msg.contains('no address associated') ||
        msg.contains('os error') ||
        msg.contains('handshake') ||
        msg.contains('does not exist') ||
        msg.contains('42p01') ||
        msg.contains('relation');
  }

  // ================================================================
  // Hashing helpers
  // ================================================================

  String _sha256(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  String _hashPassword(String password, String salt) =>
      _sha256(password + salt);

  bool _verifyPassword(String input, String storedHash) {
    // storedHash format: "salt:hash"
    final parts = storedHash.split(':');
    if (parts.length != 2) return false;
    final salt = parts[0];
    final expected = parts[1];
    return _sha256(input + salt) == expected;
  }

  String _hashToken(String rawToken) => _sha256(rawToken);

  // ================================================================
  // REGISTER (PB-005)
  // ================================================================

  /// Mendaftarkan pengguna baru.
  /// Melempar Exception jika email sudah terdaftar atau input tidak valid.
  /// Jika Supabase tidak tersedia, registrasi disimpan secara lokal.
  Future<UserModel> register({
    required String email,
    required String fullName,
    required String password,
  }) async {
    try {
      // Cek duplikat email di Supabase (timeout 3 detik agar responsif)
      final existing = await _db
          .from('users')
          .select('id')
          .eq('email', email.toLowerCase().trim())
          .maybeSingle()
          .timeout(const Duration(seconds: 3));

      if (existing != null) {
        throw Exception('Email sudah terdaftar. Silakan gunakan email lain.');
      }

      // Hash password
      final salt = _uuid.v4();
      final passwordHash = '$salt:${_hashPassword(password, salt)}';

      // Insert user ke Supabase
      final row = await _db
          .from('users')
          .insert({
            'email': email.toLowerCase().trim(),
            'password_hash': passwordHash,
            'full_name': fullName.trim(),
          })
          .select()
          .single()
          .timeout(const Duration(seconds: 3));

      return UserModel.fromMap(row);
    } catch (e) {
      if (_isConnectionError(e)) {
        debugPrint('[AuthService] Supabase tidak tersedia, register lokal: $e');
        return _registerLocally(
          email: email,
          fullName: fullName,
          password: password,
        );
      }
      rethrow;
    }
  }

  // ---- Local register ----
  Future<UserModel> _registerLocally({
    required String email,
    required String fullName,
    required String password,
  }) async {
    final Map<String, dynamic> localUsers = _getLocalUsers();
    final normalizedEmail = email.toLowerCase().trim();

    if (localUsers.containsKey(normalizedEmail)) {
      throw Exception('Email sudah terdaftar. Silakan gunakan email lain.');
    }

    final salt = _uuid.v4();
    final passwordHash = '$salt:${_hashPassword(password, salt)}';
    final userId = _uuid.v4();

    final userData = {
      'id': userId,
      'email': normalizedEmail,
      'full_name': fullName.trim(),
      'password_hash': passwordHash,
      'created_at': DateTime.now().toIso8601String(),
      'is_local': true,
    };

    localUsers[normalizedEmail] = userData;
    _localStore.write(_localUsersKey, jsonEncode(localUsers));

    return UserModel.fromMap(userData);
  }

  Map<String, dynamic> _getLocalUsers() {
    final raw = _localStore.read<String>(_localUsersKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  // ================================================================
  // LOGIN (PB-006)
  // ================================================================

  /// Login dengan email & password.
  /// Melempar Exception jika kredensial salah.
  /// Jika Supabase tidak tersedia, login menggunakan data lokal.
  Future<({UserModel user, String token})> login({
    required String email,
    required String password,
  }) async {
    try {
      // Ambil user by email dari Supabase (timeout 3 detik)
      final row = await _db
          .from('users')
          .select()
          .eq('email', email.toLowerCase().trim())
          .maybeSingle()
          .timeout(const Duration(seconds: 3));

      if (row == null) {
        throw Exception('Email atau password salah.');
      }

      // Verifikasi password
      final storedHash = row['password_hash'] as String;
      if (!_verifyPassword(password, storedHash)) {
        throw Exception('Email atau password salah.');
      }

      var user = UserModel.fromMap(row);

      // Pastikan avatar lokal tetap dipertahankan bila Supabase belum/gagal menyimpan avatar_url
      if (user.avatarUrl == null || user.avatarUrl!.isEmpty) {
        final localAvatar = await _storage.getAvatarForUser(
          userId: user.id,
          email: user.email,
        );
        if (localAvatar != null && localAvatar.isNotEmpty) {
          user = user.copyWith(avatarUrl: localAvatar);
        }
      } else {
        await _storage.saveAvatarForUser(
          userId: user.id,
          email: user.email,
          avatarData: user.avatarUrl,
        );
      }

      // Buat session token
      final rawToken = _uuid.v4();
      final tokenHash = _hashToken(rawToken);
      final expiresAt = DateTime.now()
          .toUtc()
          .add(const Duration(days: AppConstants.sessionDurationDays));

      // Simpan session ke Supabase (timeout 3 detik)
      await _db.from('sessions').insert({
        'user_id': user.id,
        'token_hash': tokenHash,
        'expires_at': expiresAt.toIso8601String(),
      }).timeout(const Duration(seconds: 3));

      // Simpan token & user info ke secure storage
      await _storage.saveSessionToken(rawToken);
      await _storage.saveUserId(user.id);
      await _storage.saveUserEmail(user.email);

      return (user: user, token: rawToken);
    } catch (e) {
      if (_isConnectionError(e)) {
        debugPrint('[AuthService] Supabase tidak tersedia, login lokal: $e');
        return _loginLocally(email: email, password: password);
      }
      rethrow;
    }
  }

  // ---- Local login ----
  Future<({UserModel user, String token})> _loginLocally({
    required String email,
    required String password,
  }) async {
    final localUsers = _getLocalUsers();
    final normalizedEmail = email.toLowerCase().trim();
    final userData = localUsers[normalizedEmail];

    if (userData == null) {
      throw Exception('Email atau password salah.');
    }

    final storedHash = userData['password_hash'] as String;
    if (!_verifyPassword(password, storedHash)) {
      throw Exception('Email atau password salah.');
    }

    var user = UserModel.fromMap(Map<String, dynamic>.from(userData as Map));
    if (user.avatarUrl == null || user.avatarUrl!.isEmpty) {
      final localAvatar = await _storage.getAvatarForUser(
        userId: user.id,
        email: user.email,
      );
      if (localAvatar != null && localAvatar.isNotEmpty) {
        user = user.copyWith(avatarUrl: localAvatar);
      }
    } else {
      await _storage.saveAvatarForUser(
        userId: user.id,
        email: user.email,
        avatarData: user.avatarUrl,
      );
    }
    final rawToken = _uuid.v4();

    // Simpan token & user info ke secure storage lokal
    await _storage.saveSessionToken(rawToken);
    await _storage.saveUserId(user.id);
    await _storage.saveUserEmail(user.email);
    // Tandai sebagai session lokal
    _localStore.write('_local_session_token', rawToken);
    _localStore.write('_local_session_user_email', normalizedEmail);
    _localStore.write(
      '_local_session_expiry',
      DateTime.now()
          .add(const Duration(days: AppConstants.sessionDurationDays))
          .toIso8601String(),
    );

    return (user: user, token: rawToken);
  }

  // ================================================================
  // UBAH PASSWORD (PB-010)
  // ================================================================

  /// Mengubah password pengguna (PB-010).
  /// Melempar Exception jika password lama salah atau user tidak ditemukan.
  Future<bool> changePassword({
    required String email,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final row = await _db
          .from('users')
          .select()
          .eq('email', email.toLowerCase().trim())
          .maybeSingle();

      if (row == null) {
        throw Exception('Pengguna tidak ditemukan.');
      }

      final storedHash = row['password_hash'] as String;
      if (!_verifyPassword(oldPassword, storedHash)) {
        throw Exception('Password lama yang Anda masukkan tidak sesuai.');
      }

      final newSalt = _uuid.v4();
      final newPasswordHash = '$newSalt:${_hashPassword(newPassword, newSalt)}';

      await _db.from('users').update({'password_hash': newPasswordHash}).eq(
          'email', email.toLowerCase().trim());

      return true;
    } catch (e) {
      if (_isConnectionError(e)) {
        return _changePasswordLocally(
          email: email,
          oldPassword: oldPassword,
          newPassword: newPassword,
        );
      }
      rethrow;
    }
  }

  Future<bool> _changePasswordLocally({
    required String email,
    required String oldPassword,
    required String newPassword,
  }) async {
    final localUsers = _getLocalUsers();
    final normalizedEmail = email.toLowerCase().trim();
    final userData = localUsers[normalizedEmail];

    if (userData == null) throw Exception('Pengguna tidak ditemukan.');

    final storedHash = userData['password_hash'] as String;
    if (!_verifyPassword(oldPassword, storedHash)) {
      throw Exception('Password lama yang Anda masukkan tidak sesuai.');
    }

    final newSalt = _uuid.v4();
    final newPasswordHash = '$newSalt:${_hashPassword(newPassword, newSalt)}';
    final updated = Map<String, dynamic>.from(userData as Map);
    updated['password_hash'] = newPasswordHash;
    localUsers[normalizedEmail] = updated;
    _localStore.write(_localUsersKey, jsonEncode(localUsers));
    return true;
  }

  // ================================================================
  // CHECK SESSION (PB-007)
  // ================================================================

  /// Cek apakah ada sesi valid di storage dan server.
  /// Return UserModel jika valid, null jika tidak valid / kedaluwarsa.
  Future<UserModel?> checkSession() async {
    final rawToken = await _storage.getSessionToken();
    if (rawToken == null) return null;

    try {
      final tokenHash = _hashToken(rawToken);

      // Validasi ke tabel sessions (timeout 3 detik)
      final sessionRow = await _db
          .from('sessions')
          .select()
          .eq('token_hash', tokenHash)
          .maybeSingle()
          .timeout(const Duration(seconds: 3));

      if (sessionRow == null) {
        await _storage.clearSession();
        return null;
      }

      final session = SessionModel.fromMap(sessionRow);

      // Cek kedaluwarsa
      if (!session.isValid) {
        await _deleteSession(tokenHash);
        await _storage.clearSession();
        return null;
      }

      // Ambil data user
      final userId = await _storage.getUserId();
      if (userId == null) {
        await _storage.clearSession();
        return null;
      }

      final userRow = await _db
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle()
          .timeout(const Duration(seconds: 3));

      if (userRow == null) {
        await _storage.clearSession();
        return null;
      }

      var user = UserModel.fromMap(userRow);
      if (user.avatarUrl == null || user.avatarUrl!.isEmpty) {
        final localAvatar = await _storage.getAvatarForUser(
          userId: user.id,
          email: user.email,
        );
        if (localAvatar != null && localAvatar.isNotEmpty) {
          user = user.copyWith(avatarUrl: localAvatar);
        }
      } else {
        await _storage.saveAvatarForUser(
          userId: user.id,
          email: user.email,
          avatarData: user.avatarUrl,
        );
      }
      return user;
    } catch (e) {
      if (_isConnectionError(e)) {
        debugPrint('[AuthService] Supabase tidak tersedia, cek sesi lokal: $e');
        return _checkLocalSession(rawToken);
      }
      rethrow;
    }
  }

  Future<UserModel?> _checkLocalSession(String rawToken) async {
    final localToken = _localStore.read<String>('_local_session_token');
    if (localToken == null || localToken != rawToken) return null;

    final expiryStr = _localStore.read<String>('_local_session_expiry');
    if (expiryStr == null) return null;

    final expiry = DateTime.tryParse(expiryStr);
    if (expiry == null || DateTime.now().isAfter(expiry)) {
      _localStore.remove('_local_session_token');
      return null;
    }

    final userEmail = _localStore.read<String>('_local_session_user_email');
    if (userEmail == null) return null;

    final localUsers = _getLocalUsers();
    final userData = localUsers[userEmail];
    if (userData == null) return null;

    var user = UserModel.fromMap(Map<String, dynamic>.from(userData as Map));
    if (user.avatarUrl == null || user.avatarUrl!.isEmpty) {
      final localAvatar = await _storage.getAvatarForUser(
        userId: user.id,
        email: user.email,
      );
      if (localAvatar != null && localAvatar.isNotEmpty) {
        user = user.copyWith(avatarUrl: localAvatar);
      }
    }
    return user;
  }

  // ================================================================
  // LOGOUT (PB-008)
  // ================================================================

  /// Logout: hapus session dari Supabase + hapus dari secure storage.
  Future<void> logout() async {
    final rawToken = await _storage.getSessionToken();
    if (rawToken != null) {
      try {
        final tokenHash = _hashToken(rawToken);
        await _deleteSession(tokenHash);
      } catch (e) {
        // Supabase tidak tersedia saat logout — tidak apa-apa, lanjutkan hapus lokal
        debugPrint('[AuthService] Logout lokal saja (Supabase offline): $e');
      }
    }
    // Hapus sesi lokal
    _localStore.remove('_local_session_token');
    _localStore.remove('_local_session_user_email');
    _localStore.remove('_local_session_expiry');
    await _storage.clearSession();
  }

  Future<void> _deleteSession(String tokenHash) async {
    await _db.from('sessions').delete().eq('token_hash', tokenHash);
  }

  // ================================================================
  // UPDATE PROFIL PENGGUNA (MODUL 5 HTTP PATCH + MODUL 6 LOCAL)
  // ================================================================

  /// Memperbarui data profil (nomor telepon dan/atau avatar_url) ke Supabase
  /// serta menyinkronkannya ke penyimpanan lokal `_local_users`.
  Future<void> updateUserProfile({
    required String userId,
    required String email,
    String? phone,
    String? avatarUrl,
    bool clearAvatar = false,
  }) async {
    final normalizedEmail = email.toLowerCase().trim();
    if (normalizedEmail.isEmpty) return;

    // 1. Selalu perbarui cache akun lokal agar tetap persisten saat offline
    _updateLocalUserProfile(
      email: normalizedEmail,
      phone: phone,
      avatarUrl: avatarUrl,
      clearAvatar: clearAvatar,
    );

    // 2. Sinkronkan ke tabel public.users Supabase (PATCH sebagian field)
    final Map<String, dynamic> payload = {
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (phone != null) {
      payload['phone'] = phone;
    }
    if (clearAvatar) {
      payload['avatar_url'] = null;
    } else if (avatarUrl != null) {
      payload['avatar_url'] = avatarUrl;
    }

    try {
      await _db
          .from('users')
          .update(payload)
          .eq('email', normalizedEmail)
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      if (_isConnectionError(e)) {
        debugPrint(
            '[AuthService] Supabase offline, profil diperbarui lokal: $e');
        return;
      }
      debugPrint('[AuthService] Gagal update profil ke Supabase: $e');
    }
  }

  void _updateLocalUserProfile({
    required String email,
    String? phone,
    String? avatarUrl,
    bool clearAvatar = false,
  }) {
    try {
      final localUsers = _getLocalUsers();
      final rawUser = localUsers[email];
      if (rawUser is! Map) return;

      final updated = Map<String, dynamic>.from(rawUser);
      if (phone != null) {
        updated['phone'] = phone;
      }
      if (clearAvatar) {
        updated.remove('avatar_url');
      } else if (avatarUrl != null) {
        updated['avatar_url'] = avatarUrl;
      }
      localUsers[email] = updated;
      _localStore.write(_localUsersKey, jsonEncode(localUsers));
    } catch (e) {
      debugPrint('[AuthService] Gagal update _local_users: $e');
    }
  }
}
