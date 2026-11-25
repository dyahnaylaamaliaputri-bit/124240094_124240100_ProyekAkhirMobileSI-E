// lib/bindings/auth_binding.dart
// GetX Binding: lazy-load AuthController untuk halaman auth
// Referensi: PB-001

import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Pastikan AuthController bersifat permanen agar currentUser tidak terhapus saat route pop
    if (!Get.isRegistered<AuthController>()) {
      Get.put<AuthController>(AuthController(), permanent: true);
    }
  }
}
