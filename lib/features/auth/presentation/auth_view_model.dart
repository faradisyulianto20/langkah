import 'package:flutter/foundation.dart';
import 'package:langkah/features/auth/domain/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthStatus { initial, loading, success, failure }

class AuthViewModel extends ChangeNotifier {
  final AuthRepository repository;

  AuthViewModel({required this.repository});

  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;
  String? _successMessage;

  AuthStatus get status => _status;
  bool get isLoading => _status == AuthStatus.loading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  User? get currentUser => repository.currentUser;
  bool get isAuthenticated => currentUser != null;

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<bool> register({
    required String email,
    required String password,
    required String username,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await repository.signUp(
        email: email,
        password: password,
        username: username,
      );
      _status = AuthStatus.success;
      _successMessage = 'Kode verifikasi OTP telah dikirimkan ke email Anda.';
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.failure;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await repository.signIn(
        email: email,
        password: password,
      );
      _status = AuthStatus.success;
      _successMessage = 'Berhasil masuk!';
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.failure;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp({
    required String email,
    required String token,
    required OtpType type,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await repository.verifyOtp(
        email: email,
        token: token,
        type: type,
      );
      _status = AuthStatus.success;
      _successMessage = type == OtpType.signup
          ? 'Email berhasil diverifikasi! Selamat datang di Langkah.'
          : 'OTP valid! Silakan buat password baru Anda.';
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.failure;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendPasswordResetOtp({
    required String email,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await repository.sendPasswordResetOtp(email: email);
      _status = AuthStatus.success;
      _successMessage = 'Kode OTP reset password telah dikirim ke email Anda.';
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.failure;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword({
    required String newPassword,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await repository.resetPassword(newPassword: newPassword);
      _status = AuthStatus.success;
      _successMessage = 'Password berhasil diperbarui. Silakan login kembali.';
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.failure;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      await repository.signOut();
      _status = AuthStatus.initial;
      _errorMessage = null;
      _successMessage = null;
      notifyListeners();
    } catch (e) {
      _status = AuthStatus.failure;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
