// test/profile_avatar_persistence_test.dart
// Pengujian persistensi foto profil saat upload, logout, login kembali, dan isolasi antar akun.

import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cinemate/controllers/auth_controller.dart';
import 'package:cinemate/controllers/profile_controller.dart';
import 'package:cinemate/models/user_model.dart';
import 'package:cinemate/repositories/auth_repository.dart';
import 'package:cinemate/services/auth_service.dart';
import 'package:cinemate/services/storage_service.dart';

class _FakeAuthRepository implements AuthRepository {
  final Map<String, UserModel> usersByEmail = {};

  @override
  Future<UserModel?> checkSession() async => null;

  @override
  Future<({UserModel user, String token})> login({
    required String email,
    required String password,
  }) async {
    final user = usersByEmail[email.toLowerCase()] ??
        UserModel(
          id: 'usr-${email.hashCode}',
          email: email,
          fullName: 'Tester',
          createdAt: DateTime(2026, 11, 25),
        );
    return (user: user, token: 'tok-$email');
  }

  @override
  Future<void> logout() async {}

  @override
  Future<UserModel> register({
    required String email,
    required String fullName,
    required String password,
  }) async {
    final user = UserModel(
      id: 'usr-${email.hashCode}',
      email: email,
      fullName: fullName,
      createdAt: DateTime(2026, 11, 25),
    );
    usersByEmail[email.toLowerCase()] = user;
    return user;
  }

  @override
  Future<bool> changePassword({
    required String email,
    required String oldPassword,
    required String newPassword,
  }) async =>
      true;
}

class _FakeAuthService implements AuthService {
  final _FakeAuthRepository repo;
  _FakeAuthService(this.repo);

  @override
  Future<void> updateUserProfile({
    required String userId,
    required String email,
    String? phone,
    String? avatarUrl,
    bool clearAvatar = false,
  }) async {
    final key = email.toLowerCase().trim();
    final existing = repo.usersByEmail[key];
    if (existing != null) {
      repo.usersByEmail[key] = existing.copyWith(
        phone: phone,
        avatarUrl: avatarUrl,
        clearAvatarUrl: clearAvatar,
      );
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeImagePicker extends ImagePicker {
  final String filePath;
  _FakeImagePicker(this.filePath);

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    return XFile(filePath);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File sampleImage;
  late StorageService storage;
  late _FakeAuthRepository repo;
  late _FakeAuthService authService;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('avatar_persist_test_');
    Hive.init(tempDir.path);

    // 1x1 valid PNG pixel bytes
    final pngBytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    );
    sampleImage = File('${tempDir.path}/sample_avatar.png')
      ..writeAsBytesSync(pngBytes);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => tempDir.path,
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
    storage.loginAttempts = 0;
    storage.lockoutUntil = null;
    repo = _FakeAuthRepository();
    authService = _FakeAuthService(repo);
    await storage.saveAvatarForUser(
      userId: 'usr-a',
      email: 'a@cinemate.id',
      avatarData: null,
    );
    await storage.saveAvatarForUser(
      userId: 'usr-b',
      email: 'b@cinemate.id',
      avatarData: null,
    );
  });

  tearDown(() => Get.reset());

  test('Foto profil tetap muncul setelah upload, logout, dan login ulang',
      () async {
    final userA = UserModel(
      id: 'usr-a',
      email: 'a@cinemate.id',
      fullName: 'User A',
      createdAt: DateTime(2026, 11, 25),
    );
    repo.usersByEmail['a@cinemate.id'] = userA;

    final authCtrl = Get.put(
      AuthController(repository: repo, storage: storage),
      permanent: true,
    );
    final profileCtrl = Get.put(
      ProfileController(
        storage: storage,
        imagePicker: _FakeImagePicker(sampleImage.path),
        authService: authService,
      ),
    );

    await authCtrl.login(email: 'a@cinemate.id', password: 'Password1');
    expect(authCtrl.currentUser.value?.id, equals('usr-a'));

    // 1. Upload foto profil
    final picked = await profileCtrl.pickProfileImage(ImageSource.gallery);
    expect(picked, isTrue);
    expect(profileCtrl.avatarPath.value, startsWith('data:image/png;base64,'));
    expect(
      ProfileController.resolveAvatarImageProvider(
          profileCtrl.resolveEffectiveAvatar(authCtrl.currentUser.value)),
      isNotNull,
    );

    // 2. Logout membersihkan state memori tanpa menghapus data tersimpan milik akun
    await authCtrl.logout();
    expect(authCtrl.currentUser.value, isNull);
    expect(profileCtrl.avatarPath.value, isNull);

    // 3. Login kembali dengan akun yang sama -> foto profil otomatis pulih
    await authCtrl.login(email: 'a@cinemate.id', password: 'Password1');
    final restoredAvatar =
        profileCtrl.resolveEffectiveAvatar(authCtrl.currentUser.value);
    expect(restoredAvatar, startsWith('data:image/png;base64,'));
    expect(
      ProfileController.resolveAvatarImageProvider(restoredAvatar),
      isNotNull,
    );
  });

  test('Isolasi avatar antar akun & hapus avatar membersihkan state', () async {
    final userA = UserModel(
      id: 'usr-a',
      email: 'a@cinemate.id',
      fullName: 'User A',
      createdAt: DateTime(2026, 11, 25),
    );
    final userB = UserModel(
      id: 'usr-b',
      email: 'b@cinemate.id',
      fullName: 'User B',
      createdAt: DateTime(2026, 11, 25),
    );
    repo.usersByEmail['a@cinemate.id'] = userA;
    repo.usersByEmail['b@cinemate.id'] = userB;

    final authCtrl = Get.put(
      AuthController(repository: repo, storage: storage),
      permanent: true,
    );
    final profileCtrl = Get.put(
      ProfileController(
        storage: storage,
        imagePicker: _FakeImagePicker(sampleImage.path),
        authService: authService,
      ),
    );

    // Login User A dan upload foto
    await authCtrl.login(email: 'a@cinemate.id', password: 'Password1');
    await profileCtrl.pickProfileImage(ImageSource.gallery);
    expect(profileCtrl.resolveEffectiveAvatar(authCtrl.currentUser.value),
        isNotNull);

    // Logout A lalu login User B -> User B tidak boleh mewarisi foto User A
    await authCtrl.logout();
    await authCtrl.login(email: 'b@cinemate.id', password: 'Password1');
    expect(profileCtrl.resolveEffectiveAvatar(authCtrl.currentUser.value),
        isNull);

    // Login kembali User A lalu hapus foto profil
    await authCtrl.logout();
    await authCtrl.login(email: 'a@cinemate.id', password: 'Password1');
    expect(profileCtrl.resolveEffectiveAvatar(authCtrl.currentUser.value),
        isNotNull);

    await profileCtrl.removeCustomAvatar();
    expect(profileCtrl.avatarPath.value, isNull);
    expect(authCtrl.currentUser.value?.avatarUrl, isNull);
    expect(profileCtrl.resolveEffectiveAvatar(authCtrl.currentUser.value),
        isNull);
  });

  test('Path cache yang terhapus dilewati dan fallback ke cloud avatarUrl',
      () async {
    await storage.saveAvatarForUser(
      userId: 'usr-a',
      email: 'a@cinemate.id',
      avatarData: '${tempDir.path}/deleted_temp_cache.jpg',
    );
    final userWithCloudAvatar = UserModel(
      id: 'usr-a',
      email: 'a@cinemate.id',
      fullName: 'User A',
      avatarUrl:
          'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      createdAt: DateTime(2026, 11, 25),
    );

    final profileCtrl = ProfileController(
      storage: storage,
      authService: authService,
    );

    final resolved = profileCtrl.resolveEffectiveAvatar(userWithCloudAvatar);
    expect(resolved, equals(userWithCloudAvatar.avatarUrl));
  });
}
