import 'package:flutter/foundation.dart';

/// Immutable model untuk statistik streak user dari tabel `user_stats`.
@immutable
class StreakData {
  final String userId;
  final int currentStreak;
  final int longestStreak;
  final int totalCompletedSteps;
  final DateTime? lastActivityDate;

  const StreakData({
    required this.userId,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalCompletedSteps,
    this.lastActivityDate,
  });

  factory StreakData.empty(String userId) {
    return StreakData(
      userId: userId,
      currentStreak: 0,
      longestStreak: 0,
      totalCompletedSteps: 0,
    );
  }

  /// Streak yang ditampilkan: 0 bila aktivitas terakhir lebih dari kemarin
  /// (streak sudah putus, walau baris database belum diperbarui).
  int effectiveCurrentStreak(DateTime now) {
    final last = lastActivityDate;
    if (last == null) return 0;
    final today = DateTime(now.year, now.month, now.day);
    final lastDay = DateTime(last.year, last.month, last.day);
    return today.difference(lastDay).inDays <= 1 ? currentStreak : 0;
  }

  StreakData copyWith({
    String? userId,
    int? currentStreak,
    int? longestStreak,
    int? totalCompletedSteps,
    DateTime? lastActivityDate,
  }) {
    return StreakData(
      userId: userId ?? this.userId,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalCompletedSteps: totalCompletedSteps ?? this.totalCompletedSteps,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
    );
  }

  factory StreakData.fromMap(Map<String, dynamic> map) {
    return StreakData(
      userId: map['user_id'] as String? ?? '',
      currentStreak: map['current_streak'] as int? ?? 0,
      longestStreak: map['longest_streak'] as int? ?? 0,
      totalCompletedSteps: map['total_completed_steps'] as int? ?? 0,
      lastActivityDate: map['last_active_date'] != null
          ? DateTime.tryParse(map['last_active_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'total_completed_steps': totalCompletedSteps,
      'last_active_date': lastActivityDate?.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StreakData &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          currentStreak == other.currentStreak &&
          longestStreak == other.longestStreak &&
          totalCompletedSteps == other.totalCompletedSteps;

  @override
  int get hashCode =>
      userId.hashCode ^
      currentStreak.hashCode ^
      longestStreak.hashCode ^
      totalCompletedSteps.hashCode;
}
