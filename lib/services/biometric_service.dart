// lib/services/biometric_service.dart
// Service integrasi autentikasi biometrik (Fingerprint & Face ID) (PB-009)
// Referensi: SRS Â§3.2 FR-009, PB-009, Modul Local Storage & Security

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'storage_service.dart';

class BiometricService {
  BiometricService._internal(
      {LocalAuthentication? auth, StorageService? storage})
      : _auth = auth ?? LocalAuthentication(),
        _storage = storage ?? StorageService();

  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService(
      {LocalAuthentication? auth, StorageService? storage}) {
    if (auth != null || storage != null) {
      return BiometricService._internal(auth: auth, storage: storage);
    }
    return _instance;
  }

  final LocalAuthentication _auth;
  final StorageService _storage;

  /// Memeriksa apakah perangkat memiliki dukungan sensor biometrik
  Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (e) {
      debugPrint('[BiometricService] isDeviceSupported error: $e');
      return false;
    }
  }

  /// Memeriksa apakah biometrik dapat dipindai saat ini
  Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (e) {
      debugPrint('[BiometricService] canCheckBiometrics error: $e');
      return false;
    }
  }

  /// Memeriksa ketersediaan keseluruhan (Hardware ada & siap digunakan)
  Future<bool> isBiometricAvailable() async {
    final supported = await isDeviceSupported();
    final canCheck = await canCheckBiometrics();
    return supported && canCheck;
  }

  /// Mendapatkan daftar tipe biometrik yang terdaftar pada perangkat
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('[BiometricService] getAvailableBiometrics error: $e');
      return [];
    }
  }

  /// Meminta autentikasi biometrik kepada pengguna (PB-009)
  Future<bool> authenticate({
    String localizedReason =
        'Pindai sidik jari atau Face ID untuk verifikasi akun Cinemate',
  }) async {
    try {
      final available = await isBiometricAvailable();
      if (!available) {
        debugPrint(
            '[BiometricService] Sensor biometrik tidak tersedia pada perangkat.');
        return false;
      }

      return await _auth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException catch (e) {
      debugPrint(
          '[BiometricService] PlatformException: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[BiometricService] Authenticate error: $e');
      return false;
    }
  }

  /// Membaca status preferensi biometrik di storage lokal
  bool get isBiometricEnabled => _storage.biometricEnabled;

  /// Mengatur preferensi biometrik
  void setBiometricEnabled(bool enabled) {
    _storage.biometricEnabled = enabled;
  }
}
