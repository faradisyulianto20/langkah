import 'package:flutter/foundation.dart';
import 'package:langkah/features/planner/domain/goal_status.dart';

/// Target mingguan dari tabel `weekly_targets`.
@immutable
class WeeklyTarget {
  final String id;
  final String userId;
  final String? monthlyGoalId;
  final String title;
  final int targetWeek;
  final int targetYear;
  final GoalStatus status;
  final DateTime? createdAt;

  const WeeklyTarget({
    required this.id,
    required this.userId,
    this.monthlyGoalId,
    required this.title,
    required this.targetWeek,
    required this.targetYear,
    this.status = GoalStatus.pending,
    this.createdAt,
  });

  /// [clearMonthlyGoalId] = true melepas tautan ke sasaran bulanan.
  WeeklyTarget copyWith({
    String? id,
    String? userId,
    String? monthlyGoalId,
    bool clearMonthlyGoalId = false,
    String? title,
    int? targetWeek,
    int? targetYear,
    GoalStatus? status,
    DateTime? createdAt,
  }) {
    return WeeklyTarget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      monthlyGoalId: clearMonthlyGoalId
          ? null
          : (monthlyGoalId ?? this.monthlyGoalId),
      title: title ?? this.title,
      targetWeek: targetWeek ?? this.targetWeek,
      targetYear: targetYear ?? this.targetYear,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory WeeklyTarget.fromMap(Map<String, dynamic> map) {
    return WeeklyTarget(
      id: map['id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      monthlyGoalId: map['monthly_goal_id'] as String?,
      title: map['title'] as String? ?? '',
      targetWeek: (map['target_week'] as num?)?.toInt() ?? 1,
      targetYear: (map['target_year'] as num?)?.toInt() ?? DateTime.now().year,
      status: GoalStatus.fromValue(map['status'] as String?),
      createdAt: map['created_at'] is String
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'monthly_goal_id': monthlyGoalId,
      'title': title,
      'target_week': targetWeek,
      'target_year': targetYear,
      'status': status.value,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeeklyTarget &&
          id == other.id &&
          userId == other.userId &&
          monthlyGoalId == other.monthlyGoalId &&
          title == other.title &&
          targetWeek == other.targetWeek &&
          targetYear == other.targetYear &&
          status == other.status;

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    monthlyGoalId,
    title,
    targetWeek,
    targetYear,
    status,
  );
}
