import 'package:langkah/core/utils/date_helpers.dart';
import 'package:langkah/features/settings/domain/streak_data.dart';

/// Logika streak murni (tanpa I/O) agar mudah dites.
///
/// Aturan: streak naik bila minimal satu tugas diselesaikan pada hari itu.
/// Hari berurutan menambah streak; melewatkan satu hari atau lebih
/// mengulang dari 1.
class StreakCalculator {
  StreakCalculator._();

  /// Dipanggil saat sebuah tugas hari ini dicentang.
  static StreakData onCompleted(StreakData s, DateTime now) {
    final today = DateHelpers.dateOnly(now);
    final last = s.lastActivityDate == null
        ? null
        : DateHelpers.dateOnly(s.lastActivityDate!);

    var current = s.currentStreak;
    if (last == null || !DateHelpers.isSameDay(last, today)) {
      final yesterday = DateTime(today.year, today.month, today.day - 1);
      final continued = last != null && DateHelpers.isSameDay(last, yesterday);
      current = continued ? s.currentStreak + 1 : 1;
    }

    return StreakData(
      userId: s.userId,
      currentStreak: current,
      longestStreak: current > s.longestStreak ? current : s.longestStreak,
      totalCompletedSteps: s.totalCompletedSteps + 1,
      lastActivityDate: today,
    );
  }

  /// Dipanggil saat centang tugas hari ini dibatalkan.
  /// [completedTodayAfter] = jumlah tugas selesai hari ini setelah dibatalkan.
  static StreakData onUncompleted(
    StreakData s,
    DateTime now, {
    required int completedTodayAfter,
  }) {
    final today = DateHelpers.dateOnly(now);
    final total = s.totalCompletedSteps > 0 ? s.totalCompletedSteps - 1 : 0;
    final last = s.lastActivityDate == null
        ? null
        : DateHelpers.dateOnly(s.lastActivityDate!);

    final revert =
        completedTodayAfter == 0 &&
        last != null &&
        DateHelpers.isSameDay(last, today);
    if (!revert) {
      return StreakData(
        userId: s.userId,
        currentStreak: s.currentStreak,
        longestStreak: s.longestStreak,
        totalCompletedSteps: total,
        lastActivityDate: s.lastActivityDate,
      );
    }

    // Hari ini tidak lagi aktif: kembalikan streak ke kondisi sebelum hari ini.
    final current = s.currentStreak > 0 ? s.currentStreak - 1 : 0;
    return StreakData(
      userId: s.userId,
      currentStreak: current,
      // Rekor yang baru dicapai hari ini ikut diturunkan.
      longestStreak: s.longestStreak == s.currentStreak
          ? current
          : s.longestStreak,
      totalCompletedSteps: total,
      lastActivityDate: current > 0
          ? DateTime(today.year, today.month, today.day - 1)
          : null,
    );
  }
}
