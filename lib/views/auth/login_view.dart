// lib/views/auth/login_view.dart
// Halaman login email & password (PB-006)
// Fitur:
//   - Form email + password dengan validasi
//   - Lockout 5 menit setelah 5x gagal (PB-006)
//   - Countdown timer saat lockout
//   - Link ke halaman Register
//   - Banner mode offline saat Supabase tidak tersedia
// Referensi: SRS §3.1, NFR-006

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../routes/app_routes.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/validators.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey =
      GlobalKey<FormState>(); // digunakan untuk memvalidasi seluruh input
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword =
      true; // buat penentu apakah pw nya mau dibintang-bintang
  Timer? _lockoutTimer;
  String _lockoutCountdown = '';

  AuthController get _ctrl => Get.find<AuthController>();

  bool _initializedArgs = false;

  @override
  void initState() {
    super.initState();
    _startLockoutTimerIfNeeded(); // cek apakah akun sedang dalam kondisi terkunci
  }

  @override
  void didChangeDependencies() {
    // fungsi ini untuk mengambil email apabila pengguna registrasi terlebih dahulu
    super.didChangeDependencies();
    if (!_initializedArgs) {
      _initializedArgs = true;
      // Passing data antar halaman: Menerima arguments via ModalRoute.of(context)
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args.containsKey('email')) {
        _emailCtrl.text = args['email'] as String;
      }
    }
  }

  void _startLockoutTimerIfNeeded() {
    if (_ctrl.isLockedOut) {
      _startCountdown();
    }
  }

  void _startCountdown() {
    // menghitung waktu setiap detik dan memperbarui tampilan teks
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final remaining = _ctrl.remainingLockout;
      if (remaining == Duration.zero) {
        timer.cancel();
        setState(() => _lockoutCountdown = '');
      } else {
        final m = remaining.inMinutes.toString().padLeft(2, '0');
        final s = (remaining.inSeconds % 60).toString().padLeft(2, '0');
        setState(() => _lockoutCountdown = '$m:$s');
      }
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose(); // menghapus cntrler input email dari RAM
    _passwordCtrl.dispose(); // menghapus cntrler input pw dari RAM
    _lockoutTimer?.cancel(); // menghentikan timer hitung mundur
    super.dispose();
  }

  Future<void> _submit() async {
    if (_ctrl.isLockedOut) {
      // cek apakah akun di lock
      _startCountdown();
      return;
    }
    if (!_formKey.currentState!.validate())
      return; // validasi input (semua input)

    final success = await _ctrl.login(
      // ambil email sama pw
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );

    if (success && mounted) {
      // Menggunakan Navigator.pushNamedAndRemoveUntil untuk membersihkan stack
      Navigator.pushNamedAndRemoveUntil(
          context, Routes.dashboard, (route) => false);
      return;
    }

    // Jika baru terkena lockout setelah percobaan ini
    if (_ctrl.isLockedOut && mounted) {
      _startCountdown();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),

              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.movie_filter_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'CINEMATE',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Banner mode offline (hanya tampil saat Supabase tidak tersedia)
              if (!SupabaseService.isInitialized)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.cloud_off_rounded,
                          color: AppColors.textSecondary, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Mode Offline Aktif: akun tersimpan di perangkat ini dan tersinkronisasi saat Supabase kembali online.',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),

              const Text(
                'Selamat datang\nkembali',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Masuk untuk melanjutkan',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 36),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Email
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'nama@email.com',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Masukkan password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Password tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Lockout warning
                    Obx(() {
                      if (!_ctrl.isLockedOut) return const SizedBox.shrink();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.45),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lock_clock,
                                color: AppColors.error, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Akun dikunci. Coba lagi dalam $_lockoutCountdown',
                                style: const TextStyle(
                                    color: AppColors.textPrimary, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    // Login button
                    Obx(() => ElevatedButton(
                          onPressed:
                              (_ctrl.isLoading.value || _ctrl.isLockedOut)
                                  ? null
                                  : _submit,
                          child: _ctrl.isLoading.value
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Masuk'),
                        )),

                    // Biometric Login Button (PB-009)
                    if (_ctrl.isBiometricEnabled) ...[
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: (_ctrl.isLoading.value || _ctrl.isLockedOut)
                            ? null
                            : () async {
                                final success =
                                    await _ctrl.loginWithBiometrics();
                                if (success && mounted) {
                                  Get.offAllNamed(Routes.dashboard);
                                }
                              },
                        icon: const Icon(
                          Icons.fingerprint_rounded,
                          color: AppColors.textPrimary,
                          size: 22,
                        ),
                        label: const Text(
                          'Masuk dengan Sidik Jari / Face ID',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          side: const BorderSide(color: AppColors.border),
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Link ke Register
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Belum punya akun? ',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, Routes.register),
                    child: const Text(
                      'Daftar',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
