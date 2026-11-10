import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  /// Registrasi akun baru dengan username, email, dan password.
  Future<void> signUp({
    required String email,
    required String password,
    required String username,
  });

  /// Masuk dengan email dan password.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  });

  /// Verifikasi kode OTP 6 digit (baik untuk signup maupun recovery).
  Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
    required OtpType type,
  });

  /// Kirim kode OTP reset password ke email pengguna.
  Future<void> sendPasswordResetOtp({
    required String email,
  });

  /// Perbarui kata sandi baru setelah OTP recovery berhasil diverifikasi.
  Future<UserResponse> resetPassword({
    required String newPassword,
  });

  /// Keluar dari sesi akun saat ini.
  Future<void> signOut();

  /// Mendapatkan user aktif saat ini.
  User? get currentUser;

  /// Mendapatkan stream perubahan state autentikasi.
  Stream<AuthState> get onAuthStateChange;
}
