import 'package:flutter/foundation.dart' show debugPrint;
import 'package:langkah/core/network/supabase_config.dart';
import 'package:langkah/core/utils/date_helpers.dart';
import 'package:langkah/features/home/data/stats_repository.dart';
import 'package:langkah/features/home/domain/streak_calculator.dart';
import 'package:langkah/features/settings/domain/streak_data.dart';

class StatsRepositoryImpl implements StatsRepository {
  final DateTime Function() _clock;

  StatsRepositoryImpl({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  String get _uid {
    final id = SupabaseConfig.client.auth.currentUser?.id;
    if (id == null) throw Exception('Sesi berakhir. Silakan login ulang.');
    return id;
  }

  Future<StreakData> _fetch(String uid) async {
    final row = await SupabaseConfig.client
        .from('user_stats')
        .select()
        .eq('user_id', uid)
        .maybeSingle();
    return row == null ? StreakData.empty(uid) : StreakData.fromMap(row);
  }

  @override
  Future<StreakData> getStats() async {
    try {
      return await _fetch(_uid);
    } catch (e) {
      debugPrint('[StatsRepository] ${e.runtimeType}: $e');
      throw Exception('Terjadi kesalahan. Silakan coba lagi.');
    }
  }

  @override
  Future<StreakData> recordTaskToggle({required bool completed}) async {
    final uid = _uid;
    final now = _clock();
    final today = DateHelpers.dateOnly(now);

    final current = await _fetch(uid);
    final StreakData next;
    if (completed) {
      next = StreakCalculator.onCompleted(current, now);
    } else {
      final rows = await SupabaseConfig.client
          .from('daily_tasks')
          .select('id')
          .eq('user_id', uid)
          .eq('is_completed', true)
          .eq('scheduled_date', DateHelpers.toSqlDate(today));
      next = StreakCalculator.onUncompleted(
        current,
        now,
        completedTodayAfter: rows.length,
      );
    }

    await SupabaseConfig.client.from('user_stats').upsert({
      'user_id': uid,
      'current_streak': next.currentStreak,
      'longest_streak': next.longestStreak,
      'total_completed_steps': next.totalCompletedSteps,
      'last_active_date': next.lastActivityDate == null
          ? null
          : DateHelpers.toSqlDate(next.lastActivityDate!),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id');
    return next;
  }
}
