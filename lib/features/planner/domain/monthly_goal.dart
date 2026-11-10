import 'package:flutter/foundation.dart';
import 'package:langkah/core/utils/date_helpers.dart';
import 'package:langkah/features/planner/domain/goal_status.dart';

/// Sasaran bulanan dari tabel `monthly_goals`.
@immutable
class MonthlyGoal {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime targetMonth;
  final GoalStatus status;
  final DateTime? createdAt;

  const MonthlyGoal({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.targetMonth,
    this.status = GoalStatus.pending,
    this.createdAt,
  });

  MonthlyGoal copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? targetMonth,
    GoalStatus? status,
    DateTime? createdAt,
  }) {
    return MonthlyGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      targetMonth: targetMonth ?? this.targetMonth,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory MonthlyGoal.fromMap(Map<String, dynamic> map) {
    return MonthlyGoal(
      id: map['id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String?,
      targetMonth:
          DateHelpers.parseSqlDate(map['target_month']) ??
          DateHelpers.firstOfMonth(DateTime.now()),
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
      'title': title,
      'description': description,
      'target_month': DateHelpers.toSqlDate(targetMonth),
      'status': status.value,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthlyGoal &&
          id == other.id &&
          userId == other.userId &&
          title == other.title &&
          description == other.description &&
          targetMonth == other.targetMonth &&
          status == other.status;

  @override
  int get hashCode =>
      Object.hash(id, userId, title, description, targetMonth, status);
}
