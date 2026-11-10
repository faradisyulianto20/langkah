import 'package:flutter_test/flutter_test.dart';
import 'package:langkah/core/utils/completion_rules.dart';
import 'package:langkah/features/home/domain/streak_calculator.dart';
import 'package:langkah/features/settings/domain/streak_data.dart';

StreakData _s({
  int current = 0,
  int longest = 0,
  int total = 0,
  DateTime? last,
}) => StreakData(
  userId: 'u',
  currentStreak: current,
  longestStreak: longest,
  totalCompletedSteps: total,
  lastActivityDate: last,
);

void main() {
  final today = DateTime(2026, 11, 10, 14, 30);

  group('StreakCalculator.onCompleted', () {
    test('tugas pertama sama sekali memulai streak 1', () {
      final r = StreakCalculator.onCompleted(_s(), today);
      expect(r.currentStreak, 1);
      expect(r.longestStreak, 1);
      expect(r.totalCompletedSteps, 1);
      expect(r.lastActivityDate, DateTime(2026, 11, 10));
    });

    test('hari berurutan menambah streak & rekor', () {
      final r = StreakCalculator.onCompleted(
        _s(current: 3, longest: 3, total: 10, last: DateTime(2026, 11, 9)),
        today,
      );
      expect(r.currentStreak, 4);
      expect(r.longestStreak, 4);
      expect(r.totalCompletedSteps, 11);
    });

    test('tugas kedua di hari yang sama tidak menambah streak', () {
      final r = StreakCalculator.onCompleted(
        _s(current: 4, longest: 4, total: 11, last: DateTime(2026, 11, 10)),
        today,
      );
      expect(r.currentStreak, 4);
      expect(r.totalCompletedSteps, 12);
    });

    test('melewatkan sehari mengulang dari 1, rekor tetap', () {
      final r = StreakCalculator.onCompleted(
        _s(current: 5, longest: 9, total: 30, last: DateTime(2026, 11, 8)),
        today,
      );
      expect(r.currentStreak, 1);
      expect(r.longestStreak, 9);
    });

    test('batas bulan & tahun dihitung benar', () {
      final r = StreakCalculator.onCompleted(
        _s(current: 2, longest: 2, last: DateTime(2025, 12, 31)),
        DateTime(2026, 1, 1, 8),
      );
      expect(r.currentStreak, 3);
    });
  });

  group('StreakCalculator.onUncompleted', () {
    test('masih ada tugas selesai hari ini: streak tetap', () {
      final r = StreakCalculator.onUncompleted(
        _s(current: 4, longest: 4, total: 12, last: DateTime(2026, 11, 10)),
        today,
        completedTodayAfter: 1,
      );
      expect(r.currentStreak, 4);
      expect(r.totalCompletedSteps, 11);
      expect(r.lastActivityDate, DateTime(2026, 11, 10));
    });

    test('tugas terakhir hari ini dibatalkan: streak dikembalikan', () {
      final r = StreakCalculator.onUncompleted(
        _s(current: 4, longest: 4, total: 11, last: DateTime(2026, 11, 10)),
        today,
        completedTodayAfter: 0,
      );
      expect(r.currentStreak, 3);
      expect(r.longestStreak, 3);
      expect(r.lastActivityDate, DateTime(2026, 11, 9));
    });

    test('streak yang baru mulai hari ini kembali ke 0 tanpa tanggal', () {
      final r = StreakCalculator.onUncompleted(
        _s(current: 1, longest: 6, total: 1, last: DateTime(2026, 11, 10)),
        today,
        completedTodayAfter: 0,
      );
      expect(r.currentStreak, 0);
      expect(r.longestStreak, 6);
      expect(r.lastActivityDate, isNull);
      expect(r.totalCompletedSteps, 0);
    });
  });

  group('StreakData.effectiveCurrentStreak', () {
    test('aktif hari ini atau kemarin dianggap berlanjut', () {
      expect(
        _s(
          current: 5,
          last: DateTime(2026, 11, 10),
        ).effectiveCurrentStreak(today),
        5,
      );
      expect(
        _s(
          current: 5,
          last: DateTime(2026, 11, 9),
        ).effectiveCurrentStreak(today),
        5,
      );
    });

    test('lebih dari kemarin atau belum pernah = 0', () {
      expect(
        _s(
          current: 5,
          last: DateTime(2026, 11, 8),
        ).effectiveCurrentStreak(today),
        0,
      );
      expect(_s(current: 5).effectiveCurrentStreak(today), 0);
    });
  });

  group('CompletionRules', () {
    final now = DateTime(2026, 11, 10, 23, 59);

    test('tugas: hanya hari yang sama', () {
      expect(
        CompletionRules.canCompleteTask(DateTime(2026, 11, 10), now),
        isTrue,
      );
      expect(
        CompletionRules.canCompleteTask(DateTime(2026, 11, 11), now),
        isFalse,
      );
      expect(
        CompletionRules.canCompleteTask(DateTime(2026, 11, 9), now),
        isFalse,
      );
    });

    test('target: hanya minggu ISO berjalan', () {
      expect(CompletionRules.canCompleteTarget(2026, 46, now), isTrue);
      expect(CompletionRules.canCompleteTarget(2026, 47, now), isFalse);
      expect(CompletionRules.canCompleteTarget(2025, 46, now), isFalse);
    });

    test('sasaran: hanya bulan berjalan', () {
      expect(
        CompletionRules.canCompleteGoal(DateTime(2026, 11, 1), now),
        isTrue,
      );
      expect(
        CompletionRules.canCompleteGoal(DateTime(2026, 12, 1), now),
        isFalse,
      );
      expect(
        CompletionRules.canCompleteGoal(DateTime(2025, 11, 1), now),
        isFalse,
      );
    });
  });
}
