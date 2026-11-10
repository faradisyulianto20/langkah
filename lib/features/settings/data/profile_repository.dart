import 'package:langkah/features/settings/domain/profile_model.dart';
import 'package:langkah/features/settings/domain/streak_data.dart';

/// Interface untuk operasi profil dan statistik user.
abstract class ProfileRepository {
  /// Ambil profil user berdasarkan [userId].
  Future<ProfileModel> getProfile(String userId);

  /// Update data profil (username, fullName).
  Future<void> updateProfile(ProfileModel profile);

  /// Ambil statistik streak user.
  Future<StreakData> getStats(String userId);
}
