import 'package:flutter/foundation.dart';
import 'package:langkah/core/network/supabase_config.dart';
import 'package:langkah/features/settings/data/profile_repository.dart';
import 'package:langkah/features/settings/domain/profile_model.dart';
import 'package:langkah/features/settings/domain/streak_data.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  @override
  Future<ProfileModel> getProfile(String userId) async {
    try {
      final data = await SupabaseConfig.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data == null) {
        return ProfileModel(id: userId);
      }

      return ProfileModel.fromMap(data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> updateProfile(ProfileModel profile) async {
    try {
      await SupabaseConfig.client.from('profiles').upsert({
        'id': profile.id,
        'username': profile.username,
        'full_name': profile.fullName,
        'avatar_url': profile.avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<StreakData> getStats(String userId) async {
    try {
      final data = await SupabaseConfig.client
          .from('user_stats')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (data == null) {
        return StreakData.empty(userId);
      }

      return StreakData.fromMap(data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(Object e) {
    final message = e.toString();
    debugPrint('[ProfileRepository] ${e.runtimeType}: $message');
    if (message.contains('row-level security')) {
      return Exception('Akses ditolak. Silakan login ulang.');
    }
    if (message.contains('connection') || message.contains('network')) {
      return Exception('Gagal terhubung ke server. Periksa koneksi internet Anda.');
    }
    return Exception('Terjadi kesalahan. Silakan coba lagi.');
  }
}
