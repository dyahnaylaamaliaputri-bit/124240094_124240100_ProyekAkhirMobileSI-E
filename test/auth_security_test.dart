// test/auth_security_test.dart
// Unit tests untuk Epic Keamanan Akun & Autentikasi Biometrik (PB-009, PB-010)

import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:cinemate/controllers/auth_controller.dart';
import 'package:cinemate/models/user_model.dart';
import 'package:cinemate/repositories/auth_repository.dart';
import 'package:cinemate/services/biometric_service.dart';
import 'package:cinemate/services/storage_service.dart';
import 'package:cinemate/utils/validators.dart';

class MockAuthRepository implements AuthRepository {
  String storedHash = '';
  String storedSalt = '';

  MockAuthRepository() {
    // Inisialisasi password lama: 'OldPassword123'
    storedSalt = 'dummy_salt_1234';
    final bytes = utf8.encode('OldPassword123$storedSalt');
    storedHash = sha256.convert(bytes).toString();
  }

  @override
  Future<UserModel?> checkSession() async => null;

  @override
  Future<({UserModel user, String token})> login(
      {required String email, required String password}) async {
    return (
      user: UserModel(
        id: 'usr-1',
        email: email,
        fullName: 'Test User',
        createdAt: DateTime.now(),
      ),
      token: 'mock-token',
    );
  }

  @override
  Future<void> logout() async {}

  @override
  Future<UserModel> register({
    required String email,
    required String fullName,
    required String password,
  }) async {
    return UserModel(
      id: 'usr-new',
      email: email,
      fullName: fullName,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<bool> changePassword({
    required String email,
    required String oldPassword,
    required String newPassword,
  }) async {
    // Verifikasi password lama dengan salt
    final verifyBytes = utf8.encode('$oldPassword$storedSalt');
    final computedHash = sha256.convert(verifyBytes).toString();

    if (computedHash != storedHash) {
      throw Exception('Kata sandi lama salah');
    }

    // Buat salt baru dan hash baru
    final newSalt = 'new_salt_5678';
    final newBytes = utf8.encode('$newPassword$newSalt');
    storedSalt = newSalt;
    storedHash = sha256.convert(newBytes).toString();
    return true;
  }
}

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

  setUp(() {
    Get.reset();
    storage = StorageService();
    storage.biometricEnabled = false;
  });

  group('PB-009: Biometric Authentication & Preference Tests', () {
    test(
        'Biometric preference should toggle via BiometricService and StorageService',
        () {
      final bioService = BiometricService(storage: storage);
      expect(bioService.isBiometricEnabled, isFalse);

      bioService.setBiometricEnabled(true);
      expect(bioService.isBiometricEnabled, isTrue);
      expect(storage.biometricEnabled, isTrue);

      bioService.setBiometricEnabled(false);
      expect(bioService.isBiometricEnabled, isFalse);
      expect(storage.biometricEnabled, isFalse);
    });

    test('AuthController reflects biometric toggle', () {
      final authCtrl = AuthController(storage: storage);
      expect(authCtrl.isBiometricEnabled, isFalse);

      authCtrl.setBiometricEnabled(true);
      expect(authCtrl.isBiometricEnabled, isTrue);
      expect(storage.biometricEnabled, isTrue);
    });
  });

  group('PB-010: Change Password & Security Hashing Tests', () {
    test(
        'Password validator should validate minimum length and alphanumeric rules',
        () {
      expect(Validators.validatePassword(''), 'Password tidak boleh kosong');
      expect(
          Validators.validatePassword('short1'), 'Password minimal 8 karakter');
      expect(Validators.validatePassword('alllettersonly'),
          'Password harus mengandung angka');
      expect(Validators.validatePassword('1234567890'),
          'Password harus mengandung huruf');
      expect(Validators.validatePassword('Cinemate2026'), isNull);
    });

    test('Confirm password validator should ensure matching passwords', () {
      expect(Validators.validateConfirmPassword('', 'Cinemate2026'),
          'Konfirmasi password tidak boleh kosong');
      expect(Validators.validateConfirmPassword('WrongPass1', 'Cinemate2026'),
          'Password tidak cocok');
      expect(Validators.validateConfirmPassword('Cinemate2026', 'Cinemate2026'),
          isNull);
    });

    test('changePassword should fail if old password does not match hash',
        () async {
      final mockRepo = MockAuthRepository();
      expect(
        () => mockRepo.changePassword(
          email: 'user@cinemate.id',
          oldPassword: 'WrongOldPassword',
          newPassword: 'BrandNewPass2026',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test(
        'changePassword should succeed and update hash with salt when old password matches',
        () async {
      final mockRepo = MockAuthRepository();
      final initialHash = mockRepo.storedHash;

      final result = await mockRepo.changePassword(
        email: 'user@cinemate.id',
        oldPassword: 'OldPassword123',
        newPassword: 'BrandNewPass2026',
      );

      expect(result, isTrue);
      expect(mockRepo.storedHash, isNot(equals(initialHash)));

      // Verifikasi bahwa password lama sudah tidak bisa dipakai lagi
      expect(
        () => mockRepo.changePassword(
          email: 'user@cinemate.id',
          oldPassword: 'OldPassword123',
          newPassword: 'AnotherPassword99',
        ),
        throwsA(isA<Exception>()),
      );

      // Verifikasi password baru dapat digunakan untuk pergantian berikutnya
      final secondChange = await mockRepo.changePassword(
        email: 'user@cinemate.id',
        oldPassword: 'BrandNewPass2026',
        newPassword: 'ThirdPassword2026',
      );
      expect(secondChange, isTrue);
    });

    test(
        'AuthController.changePassword should handle unauthenticated user gracefully',
        () async {
      final mockRepo = MockAuthRepository();
      final authCtrl = AuthController(repository: mockRepo, storage: storage);

      final result = await authCtrl.changePassword(
        oldPassword: 'OldPassword123',
        newPassword: 'BrandNewPass2026',
      );

      expect(result, isFalse);
    });

    test('AuthController.changePassword should succeed for authenticated user',
        () async {
      final mockRepo = MockAuthRepository();
      final authCtrl = AuthController(repository: mockRepo, storage: storage);
      authCtrl.currentUser.value = UserModel(
        id: 'usr-1',
        email: 'user@cinemate.id',
        fullName: 'Cinemate User',
        createdAt: DateTime.now(),
      );

      final result = await authCtrl.changePassword(
        oldPassword: 'OldPassword123',
        newPassword: 'BrandNewPass2026',
      );

      expect(result, isTrue);
    });
  });
}
