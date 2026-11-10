import 'dart:typed_data';

import 'package:langkah/features/settings/domain/profile_model.dart';
import 'package:langkah/features/settings/domain/streak_data.dart';

/// Interface untuk operasi profil dan statistik user.
abstract class ProfileRepository {
  /// Ambil profil user berdasarkan [userId].
  Future<ProfileModel> getProfile(String userId);

  /// Update data profil (username, fullName).
  Future<void> updateProfile(ProfileModel profile);

  /// Unggah foto profil ke Storage lalu simpan URL-nya di profil.
  /// Mengembalikan URL publik foto baru.
  Future<String> uploadAvatar(
    String userId,
    Uint8List bytes, {
    required String contentType,
    required String extension,
  });

  /// Ambil statistik streak user.
  Future<StreakData> getStats(String userId);
}
