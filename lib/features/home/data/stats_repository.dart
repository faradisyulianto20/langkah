import 'package:langkah/features/settings/domain/streak_data.dart';

abstract class StatsRepository {
  Future<StreakData> getStats();

  /// Memperbarui `user_stats` setelah sebuah tugas hari ini dicentang
  /// ([completed] = true) atau dibatalkan ([completed] = false).
  Future<StreakData> recordTaskToggle({required bool completed});
}
