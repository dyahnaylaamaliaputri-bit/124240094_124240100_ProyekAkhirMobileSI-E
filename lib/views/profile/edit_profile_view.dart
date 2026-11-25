// lib/views/profile/edit_profile_view.dart
// Halaman form edit profil pengguna: nama, nomor telepon & foto profil kamera/galeri (PB-061, PB-062)

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../services/storage_service.dart';
import '../../utils/app_colors.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final AuthController _authCtrl = Get.isRegistered<AuthController>()
      ? Get.find<AuthController>()
      : Get.put(AuthController());
  final ProfileController _profileCtrl = Get.isRegistered<ProfileController>()
      ? Get.find<ProfileController>()
      : Get.put(ProfileController());

  final _formKey = GlobalKey<FormState>();

  late TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    final user = _authCtrl.currentUser.value;
    final storage = StorageService();
    final savedAvatar = user != null
        ? (storage.getAvatarPath(user.id) ??
            storage.getAvatarPath(user.email.toLowerCase()))
        : null;
    if (savedAvatar != null && savedAvatar.isNotEmpty) {
      _profileCtrl.avatarPath.value = savedAvatar;
    } else {
      _profileCtrl.loadAvatar();
    }
    _phoneCtrl = TextEditingController(
      text: (user?.phone != null && user!.phone!.isNotEmpty)
          ? user.phone!
          : '081234567890',
    );
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndSaveAvatar(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 600,
      );
      if (picked == null) return;

      String storedValue;
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        storedValue = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      } else {
        storedValue = picked.path;
      }

      _profileCtrl.avatarPath.value = storedValue;
      final current = _authCtrl.currentUser.value;
      if (current != null) {
        final storage = StorageService();
        storage.setAvatarPath(storedValue, current.id);
        storage.setAvatarPath(storedValue, current.email.toLowerCase());
        _authCtrl.currentUser.value = current.copyWith(avatarUrl: storedValue);
      }
      if (mounted) setState(() {});
    } catch (e) {
      Get.snackbar(
        'Gagal Memilih Foto',
        'Pastikan izin kamera/galeri tersedia.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.card,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _removeAvatar() async {
    _profileCtrl.avatarPath.value = null;
    final current = _authCtrl.currentUser.value;
    if (current != null) {
      final storage = StorageService();
      storage.setAvatarPath(null, current.id);
      storage.setAvatarPath(null, current.email.toLowerCase());
      _authCtrl.currentUser.value = current.copyWith(avatarUrl: null);
    }
    if (mounted) setState(() {});
  }

  void _showImagePickerModal() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Foto Profil',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading:
                  const Icon(Icons.camera_alt_outlined, color: AppColors.gold),
              title: const Text('Ambil dari Kamera',
                  style: TextStyle(color: AppColors.textPrimary)),
              onTap: () async {
                Get.back();
                await _pickAndSaveAvatar(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.gold),
              title: const Text('Pilih dari Galeri',
                  style: TextStyle(color: AppColors.textPrimary)),
              onTap: () async {
                Get.back();
                await _pickAndSaveAvatar(ImageSource.gallery);
              },
            ),
            if (_profileCtrl.avatarPath.value != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.primary),
                title: const Text('Hapus Foto Profil',
                    style: TextStyle(color: AppColors.primary)),
                onTap: () async {
                  Get.back();
                  await _removeAvatar();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;

    final current = _authCtrl.currentUser.value;
    if (current != null) {
      final avatar = _profileCtrl.avatarPath.value ?? current.avatarUrl;
      final updated = current.copyWith(
        phone: _phoneCtrl.text.trim(),
        avatarUrl: avatar,
      );
      _authCtrl.currentUser.value = updated;
      if (avatar != null && avatar.isNotEmpty) {
        final storage = StorageService();
        storage.setAvatarPath(avatar, current.id);
        storage.setAvatarPath(avatar, current.email.toLowerCase());
      }
    }

    Get.back();
    Get.snackbar(
      'Profil Diperbarui',
      'Perubahan profil berhasil disimpan ke sesi lokal.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.card,
      colorText: Colors.white,
      icon: const Icon(Icons.check_circle_rounded, color: AppColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary, size: 18),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'EDIT PROFIL',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 16,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Selector Badge Avatar & Unggah Foto (PB-061)
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Obx(() {
                          final path = _profileCtrl.avatarPath.value;
                          final userName =
                              _authCtrl.currentUser.value?.fullName ?? 'U';
                          final initial = userName.isNotEmpty
                              ? userName[0].toUpperCase()
                              : 'U';

                          ImageProvider? imageProvider;
                          if (path != null && path.isNotEmpty) {
                            if (path.startsWith('data:image')) {
                              final b64 = path.split(',').last;
                              imageProvider = MemoryImage(base64Decode(b64));
                            } else if (kIsWeb ||
                                path.startsWith('http') ||
                                path.startsWith('blob:')) {
                              imageProvider = NetworkImage(path);
                            } else if (File(path).existsSync()) {
                              imageProvider = FileImage(File(path));
                            }
                          }

                          if (imageProvider != null) {
                            return CircleAvatar(
                              radius: 48,
                              backgroundColor: AppColors.gold,
                              child: CircleAvatar(
                                radius: 45,
                                backgroundImage: imageProvider,
                              ),
                            );
                          }

                          return CircleAvatar(
                            radius: 45,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _showImagePickerModal,
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: const BoxDecoration(
                                color: AppColors.gold,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _showImagePickerModal,
                      icon: const Icon(Icons.photo_camera_rounded, size: 14),
                      label: const Text(
                        'Unggah Foto Profil',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.gold,
                        side: const BorderSide(color: AppColors.gold),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // 2. Nama Lengkap (Otomatis dari data registrasi, tidak perlu input ulang)
              const Text(
                'Nama Lengkap',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.card.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, color: AppColors.gold),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _authCtrl.currentUser.value?.fullName.isNotEmpty == true
                            ? _authCtrl.currentUser.value!.fullName
                            : (_authCtrl.currentUser.value?.email
                                    .split('@')
                                    .first ??
                                'Pengguna Cinemate'),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Icon(Icons.lock_outline_rounded,
                        color: AppColors.textDisabled, size: 16),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3. Field Nomor Telepon
              const Text(
                'Nomor Telepon / WhatsApp',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.card,
                  hintText: 'Contoh: 081234567890',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  prefixIcon:
                      const Icon(Icons.phone_outlined, color: AppColors.gold),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Nomor telepon tidak boleh kosong';
                  }
                  if (val.trim().length < 10) {
                    return 'Nomor telepon minimal 10 digit';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // 4. Tombol Simpan
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.check_rounded, color: Colors.white),
                  label: const Text(
                    'Simpan Perubahan',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  onPressed: _saveProfile,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
