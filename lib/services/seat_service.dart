// lib/services/seat_service.dart
// Service manajemen concurrency lock & temporary hold 10 menit kursi bioskop (PB-028, PB-029)

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/seat_lock_model.dart';
import '../utils/constants.dart';

class SeatLockResult {
  final bool isSuccess;
  final List<String> lockedSeats;
  final List<String> conflictingSeats;
  final String message;
  final DateTime? lockedUntil;

  const SeatLockResult({
    required this.isSuccess,
    this.lockedSeats = const [],
    this.conflictingSeats = const [],
    required this.message,
    this.lockedUntil,
  });

  factory SeatLockResult.success({
    required List<String> lockedSeats,
    required DateTime lockedUntil,
    String message = 'Kursi berhasil dikunci untuk checkout',
  }) {
    return SeatLockResult(
      isSuccess: true,
      lockedSeats: lockedSeats,
      lockedUntil: lockedUntil,
      message: message,
    );
  }

  factory SeatLockResult.collision({
    required List<String> conflictingSeats,
    String? message,
  }) {
    final seatsStr = conflictingSeats.join(', ');
    return SeatLockResult(
      isSuccess: false,
      conflictingSeats: conflictingSeats,
      message: message ??
          'Maaf, kursi $seatsStr baru saja dipilih oleh pengguna lain.',
    );
  }

  @override
  String toString() =>
      'SeatLockResult(success: $isSuccess, locked: $lockedSeats, conflicts: $conflictingSeats, msg: $message)';
}

class SeatService extends GetxService {
  static SeatService? _instance;
  static SeatService get instance => _instance ??= SeatService();

  final SupabaseClient? _supabaseClient;
  Box? _box;

  SeatService({SupabaseClient? supabaseClient, Box? box})
      : _supabaseClient = supabaseClient,
        _box = box {
    _instance = this;
  }

  SupabaseClient? get _client {
    if (_supabaseClient != null) return _supabaseClient;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Membuka Hive Box untuk persistensi kunci kursi
  Future<Box> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    if (Hive.isBoxOpen(AppConstants.boxSeatLocks)) {
      _box = Hive.box(AppConstants.boxSeatLocks);
      return _box!;
    }
    _box = await Hive.openBox(AppConstants.boxSeatLocks);
    return _box!;
  }

  /// Mengunci daftar kursi untuk showtime tertentu (PB-028: Concurrency Check & PB-029: 10 Menit Hold)
  Future<SeatLockResult> lockSeats({
    required String showtimeId,
    required List<String> seatLabels,
    required String userId,
    Duration holdDuration = const Duration(minutes: 10),
  }) async {
    if (seatLabels.isEmpty) {
      return const SeatLockResult(
        isSuccess: false,
        message: 'Tidak ada kursi yang dipilih untuk dikunci.',
      );
    }

    // Bersihkan kunci yang sudah expired terlebih dahulu
    await cleanExpiredLocks();

    final activeLocks = await getActiveLocks(showtimeId);
    final collisions = <String>[];

    for (final seat in seatLabels) {
      // Periksa apakah kursi sedang dikunci pengguna lain yang belum kedaluwarsa
      final existingLock = activeLocks.firstWhereOrNull(
        (l) => l.seatLabel == seat && !l.isExpired,
      );

      if (existingLock != null && existingLock.userId != userId) {
        collisions.add(seat);
      }
    }

    // Jika terjadi bentrok dengan pengguna lain (PB-028 Concurrency Collision)
    if (collisions.isNotEmpty) {
      debugPrint(
          '[SeatService] Collision detected pada showtime $showtimeId untuk kursi: $collisions');
      return SeatLockResult.collision(conflictingSeats: collisions);
    }

    final lockedUntil = DateTime.now().add(holdDuration);
    final newLocks = <SeatLockModel>[];

    // Simpan kunci kursi baru
    final box = await _getBox();
    for (final seat in seatLabels) {
      final lockId = '${showtimeId}_$seat';
      final lockModel = SeatLockModel(
        id: lockId,
        showtimeId: showtimeId,
        seatLabel: seat,
        userId: userId,
        lockedUntil: lockedUntil,
        createdAt: DateTime.now(),
      );
      newLocks.add(lockModel);
      await box.put(lockId, lockModel.toJson());

      // Sinkronisasi cloud ke Supabase seat_locks jika online
      _syncLockToSupabase(lockModel);
    }

    debugPrint(
        '[SeatService] Sukses mengunci kursi $seatLabels untuk user $userId hingga $lockedUntil');
    return SeatLockResult.success(
      lockedSeats: seatLabels,
      lockedUntil: lockedUntil,
      message: 'Kursi berhasil dikunci selama ${holdDuration.inMinutes} menit.',
    );
  }

  /// Melepaskan kunci kursi (saat checkout selesai, dibatalkan, atau timer expired)
  Future<bool> releaseSeats({
    required String showtimeId,
    required List<String> seatLabels,
    required String userId,
    bool force = false,
  }) async {
    try {
      final box = await _getBox();
      for (final seat in seatLabels) {
        final lockId = '${showtimeId}_$seat';
        final raw = box.get(lockId);
        if (raw != null) {
          final lock = SeatLockModel.fromJson(Map<String, dynamic>.from(raw));
          if (force || lock.userId == userId || lock.isExpired) {
            await box.delete(lockId);
            _deleteLockFromSupabase(showtimeId, seat);
          }
        }
      }
      debugPrint('[SeatService] Kursi $seatLabels berhasil dilepas.');
      return true;
    } catch (e) {
      debugPrint('[SeatService] Error melepas kursi: $e');
      return false;
    }
  }

  /// Mengambil daftar semua kunci kursi aktif untuk showtime
  Future<List<SeatLockModel>> getActiveLocks(String showtimeId) async {
    try {
      final box = await _getBox();
      final active = <SeatLockModel>[];
      final now = DateTime.now();

      for (final key in box.keys) {
        final raw = box.get(key);
        if (raw != null && raw is Map) {
          final lock = SeatLockModel.fromJson(Map<String, dynamic>.from(raw));
          if (lock.showtimeId == showtimeId && lock.lockedUntil.isAfter(now)) {
            active.add(lock);
          }
        }
      }
      return active;
    } catch (e) {
      debugPrint('[SeatService] Error getActiveLocks: $e');
      return [];
    }
  }

  /// Mengambil label kursi yang terkunci dan tidak dapat dipilih pengguna saat ini
  Future<List<String>> getLockedSeatLabels(
    String showtimeId, {
    String? excludeUserId,
  }) async {
    final active = await getActiveLocks(showtimeId);
    return active
        .where((l) => excludeUserId == null || l.userId != excludeUserId)
        .map((l) => l.seatLabel)
        .toList();
  }

  /// Membersihkan seluruh kunci yang sudah kedaluwarsa (Auto-release expired hold)
  Future<int> cleanExpiredLocks() async {
    try {
      final box = await _getBox();
      final now = DateTime.now();
      final keysToDelete = <dynamic>[];

      for (final key in box.keys) {
        final raw = box.get(key);
        if (raw != null && raw is Map) {
          final lock = SeatLockModel.fromJson(Map<String, dynamic>.from(raw));
          if (now.isAfter(lock.lockedUntil)) {
            keysToDelete.add(key);
          }
        }
      }

      for (final k in keysToDelete) {
        await box.delete(k);
      }
      return keysToDelete.length;
    } catch (e) {
      debugPrint('[SeatService] Error cleanExpiredLocks: $e');
      return 0;
    }
  }

  /// Simulasi kunci kursi oleh pengguna lain untuk pengujian collision concurrency (PB-028)
  Future<void> simulateConcurrentLock({
    required String showtimeId,
    required String seatLabel,
    required String otherUserId,
    Duration holdDuration = const Duration(minutes: 10),
  }) async {
    final box = await _getBox();
    final lockId = '${showtimeId}_$seatLabel';
    final lockModel = SeatLockModel(
      id: lockId,
      showtimeId: showtimeId,
      seatLabel: seatLabel,
      userId: otherUserId,
      lockedUntil: DateTime.now().add(holdDuration),
      createdAt: DateTime.now(),
    );
    await box.put(lockId, lockModel.toJson());
  }

  /// Menghapus seluruh data kunci (untuk reset dan unit testing)
  Future<void> clearAllLocks() async {
    try {
      final box = await _getBox();
      await box.clear();
    } catch (_) {}
  }

  // Helper sinkronisasi Supabase di latar belakang
  void _syncLockToSupabase(SeatLockModel lock) {
    final client = _client;
    if (client == null) return;
    client.from('seat_locks').upsert({
      'showtime_id': lock.showtimeId,
      'seat_label': lock.seatLabel,
      'user_id': lock.userId,
      'locked_until': lock.lockedUntil.toIso8601String(),
    }).catchError((e) {
      debugPrint('[SeatService] Supabase seat lock upsert fallback: $e');
      return null;
    });
  }

  void _deleteLockFromSupabase(String showtimeId, String seatLabel) {
    final client = _client;
    if (client == null) return;
    client
        .from('seat_locks')
        .delete()
        .eq('showtime_id', showtimeId)
        .eq('seat_label', seatLabel)
        .catchError((e) {
      debugPrint('[SeatService] Supabase seat lock delete fallback: $e');
      return null;
    });
  }
}
