// lib/views/dashboard/tabs/profile_tab.dart
// Tab Profil Pengguna yang Disederhanakan Sesuai Modul II - VIII
// Menampilkan data yang diinput saat registrasi, avatar per akun, edit profil, dan tombol keluar.

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/profile_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../services/storage_service.dart';
import '../../../utils/app_colors.dart';

class ProfileTab extends StatelessWidget {
  final VoidCallback onLogoutRequested;

  const ProfileTab({
    super.key,
    required this.onLogoutRequested,
  });

  @override
  Widget build(BuildContext context) {
    final authCtrl = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController());
    final profileCtrl = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : Get.put(ProfileController());
    final storage = StorageService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'PROFIL PENGGUNA',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Obx(() {
          final user = authCtrl.currentUser.value;
          final name = user?.fullName.isNotEmpty == true
              ? user!.fullName
              : 'Pengguna Cinemate';
          final email = user?.email ?? '-';
          final phone = (user?.phone != null && user!.phone!.isNotEmpty)
              ? user.phone!
              : '081234567890';
          final userId = user?.id ?? '-';

          // Format tanggal bergabung
          String joinedDate = '24 November 2026';
          if (user?.createdAt != null) {
            final dt = user!.createdAt;
            final months = [
              '',
              'Januari',
              'Februari',
              'Maret',
              'April',
              'Mei',
              'Juni',
              'Juli',
              'Agustus',
              'September',
              'Oktober',
              'November',
              'Desember'
            ];
            joinedDate = '${dt.day} ${months[dt.month]} ${dt.year}';
          }

          // Cek avatar lokal khusus user ID / email aktif (persisten di Web & Mobile)
          final savedByUser = user != null
              ? (storage.getAvatarPath(user.id) ??
                  storage.getAvatarPath(user.email.toLowerCase()))
              : null;
          final effectiveAvatar =
              (savedByUser != null && savedByUser.isNotEmpty)
                  ? savedByUser
                  : (profileCtrl.avatarPath.value?.isNotEmpty == true
                      ? profileCtrl.avatarPath.value
                      : user?.avatarUrl);

          ImageProvider? avatarProvider;
          if (effectiveAvatar != null && effectiveAvatar.isNotEmpty) {
            if (effectiveAvatar.startsWith('data:image')) {
              final b64 = effectiveAvatar.split(',').last;
              avatarProvider = MemoryImage(base64Decode(b64));
            } else if (kIsWeb ||
                effectiveAvatar.startsWith('http') ||
                effectiveAvatar.startsWith('blob:')) {
              avatarProvider = NetworkImage(effectiveAvatar);
            } else if (File(effectiveAvatar).existsSync()) {
              avatarProvider = FileImage(File(effectiveAvatar));
            }
          }
          final hasAvatarImage = avatarProvider != null;

          return Column(
            children: [
              // ── 1. HEADER AVATAR & NAMA PENGGUNA ──────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.cardGradient,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: AppColors.primary,
                          backgroundImage: avatarProvider,
                          child: hasAvatarImage
                              ? null
                              : Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.card, width: 2),
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.black,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded,
                              color: AppColors.gold, size: 14),
                          SizedBox(width: 5),
                          Text(
                            'Akun Terverifikasi',
                            style: TextStyle(
                              color: AppColors.gold,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── 2. CARD DATA PENDAFTARAN PENGGUNA ─────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.badge_outlined,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'DATA AKUN SAYA',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.divider, height: 1),
                    const SizedBox(height: 12),

                    _buildInfoRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Nama Lengkap',
                      value: name,
                    ),
                    const SizedBox(height: 12),

                    _buildInfoRow(
                      icon: Icons.email_outlined,
                      label: 'Email Terdaftar',
                      value: email,
                    ),
                    const SizedBox(height: 12),

                    _buildInfoRow(
                      icon: Icons.phone_outlined,
                      label: 'Nomor Telepon',
                      value: phone,
                    ),
                    const SizedBox(height: 12),

                    _buildInfoRow(
                      icon: Icons.fingerprint_rounded,
                      label: 'ID Pengguna',
                      value: userId.length > 20
                          ? '${userId.substring(0, 18)}...'
                          : userId,
                    ),
                    const SizedBox(height: 12),

                    _buildInfoRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'Member Sejak',
                      value: joinedDate,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── 3. TOMBOL EDIT PROFIL ──────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => Get.toNamed(Routes.editProfile),
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text(
                    'Edit Profil & Ganti Foto',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── 4. TOMBOL KELUAR / LOGOUT ─────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _showLogoutConfirmDialog(context),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text(
                    'Keluar dari Akun',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(
                      color: AppColors.error.withValues(alpha: 0.6),
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showLogoutConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Konfirmasi Keluar',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun Cinemate?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onLogoutRequested();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}
