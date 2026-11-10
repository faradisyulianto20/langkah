import 'package:langkah/core/utils/date_helpers.dart';

/// Aturan "hanya bisa dicentang pada periodenya".
///
/// Rencana (tugas/target/sasaran) tetap bisa diedit kapan saja, tetapi
/// hanya bisa ditandai selesai saat hari/minggu/bulannya sedang berjalan.
class CompletionRules {
  CompletionRules._();

  static const taskLockedMessage =
      'Tugas hanya bisa dicentang pada harinya. Rencana tetap bisa diedit.';
  static const targetLockedMessage =
      'Target hanya bisa dicentang pada minggunya.';
  static const goalLockedMessage =
      'Sasaran hanya bisa dicentang pada bulannya.';

  static bool canCompleteTask(DateTime scheduledDate, DateTime now) =>
      DateHelpers.isSameDay(scheduledDate, now);

  static bool canCompleteTarget(int year, int week, DateTime now) {
    final iso = DateHelpers.isoWeek(now);
    return iso.year == year && iso.week == week;
  }

  static bool canCompleteGoal(DateTime targetMonth, DateTime now) =>
      targetMonth.year == now.year && targetMonth.month == now.month;
}
