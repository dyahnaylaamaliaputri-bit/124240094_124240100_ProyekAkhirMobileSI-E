// lib/repositories/auth_repository.dart
// Abstract class (interface) + implementasi konkret untuk auth
// OOP: abstraksi + polimorfisme (SRS B-07)

import '../models/user_model.dart';
import '../services/auth_service.dart';

// ── Abstract repository ──────────────────────────────────────────────────────
abstract class AuthRepository {
  Future<UserModel> register({
    required String email,
    required String fullName,
    required String password,
  });

  Future<({UserModel user, String token})> login({
    required String email,
    required String password,
  });

  Future<UserModel?> checkSession();

  Future<void> logout();

  Future<bool> changePassword({
    required String email,
    required String oldPassword,
    required String newPassword,
  });
}

// ── Concrete implementation ──────────────────────────────────────────────────
class AuthRepositoryImpl implements AuthRepository {
  final AuthService _authService;

  AuthRepositoryImpl({AuthService? authService})
      : _authService = authService ?? AuthService();

  @override
  Future<UserModel> register({
    required String email,
    required String fullName,
    required String password,
  }) =>
      _authService.register(
        email: email,
        fullName: fullName,
        password: password,
      );

  @override
  Future<({UserModel user, String token})> login({
    required String email,
    required String password,
  }) =>
      _authService.login(email: email, password: password);

  @override
  Future<UserModel?> checkSession() => _authService.checkSession();

  @override
  Future<void> logout() => _authService.logout();

  @override
  Future<bool> changePassword({
    required String email,
    required String oldPassword,
    required String newPassword,
  }) =>
      _authService.changePassword(
        email: email,
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
}
