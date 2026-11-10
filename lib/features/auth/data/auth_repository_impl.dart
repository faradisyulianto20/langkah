import 'dart:io';
import 'package:langkah/core/network/supabase_config.dart';
import 'package:langkah/features/auth/domain/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient? _customClient;

  AuthRepositoryImpl({SupabaseClient? client}) : _customClient = client;

  SupabaseClient get _client {
    if (_customClient != null) return _customClient;
    return SupabaseConfig.client;
  }

  @override
  User? get currentUser {
    if (!SupabaseConfig.isInitialized && _customClient == null) return null;
    return _client.auth.currentUser;
  }

  @override
  Stream<AuthState> get onAuthStateChange {
    if (!SupabaseConfig.isInitialized && _customClient == null) {
      return const Stream.empty();
    }
    return _client.auth.onAuthStateChange;
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'username': username.trim(),
        },
      );
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } on SocketException {
      throw 'Tidak dapat terhubung ke internet. Periksa koneksi Anda.';
    } catch (e) {
      throw 'Terjadi kesalahan saat pendaftaran: ${e.toString()}';
    }
  }

  @override
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } on SocketException {
      throw 'Tidak dapat terhubung ke internet. Periksa koneksi Anda.';
    } catch (e) {
      throw 'Terjadi kesalahan saat masuk: ${e.toString()}';
    }
  }

  @override
  Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
    required OtpType type,
  }) async {
    try {
      return await _client.auth.verifyOTP(
        email: email.trim(),
        token: token.trim(),
        type: type,
      );
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } on SocketException {
      throw 'Tidak dapat terhubung ke internet. Periksa koneksi Anda.';
    } catch (e) {
      throw 'Terjadi kesalahan saat verifikasi OTP: ${e.toString()}';
    }
  }

  @override
  Future<void> sendPasswordResetOtp({
    required String email,
  }) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email.trim(),
      );
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } on SocketException {
      throw 'Tidak dapat terhubung ke internet. Periksa koneksi Anda.';
    } catch (e) {
      throw 'Terjadi kesalahan saat mengirim kode reset: ${e.toString()}';
    }
  }

  @override
  Future<UserResponse> resetPassword({
    required String newPassword,
  }) async {
    try {
      return await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } on SocketException {
      throw 'Tidak dapat terhubung ke internet. Periksa koneksi Anda.';
    } catch (e) {
      throw 'Terjadi kesalahan saat memperbarui kata sandi: ${e.toString()}';
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Terjadi kesalahan saat keluar: ${e.toString()}';
    }
  }

  String _handleAuthException(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('user already registered') || msg.contains('already exists')) {
      return 'Email ini sudah terdaftar. Silakan masuk.';
    }
    if (msg.contains('invalid login credentials') || msg.contains('invalid credentials')) {
      return 'Email atau password yang Anda masukkan salah.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Email Anda belum dikonfirmasi. Masukkan kode OTP yang dikirim ke email.';
    }
    if (msg.contains('token has expired') || msg.contains('otp expired')) {
      return 'Kode OTP telah kedaluwarsa. Silakan minta kode baru.';
    }
    if (msg.contains('invalid token') || msg.contains('token is invalid') || msg.contains('otp')) {
      return 'Kode OTP tidak cocok. Periksa kembali 6 digit yang diterima.';
    }
    if (msg.contains('rate limit')) {
      return 'Terlalu banyak percobaan. Harap tunggu beberapa saat lagi.';
    }
    return e.message;
  }
}
