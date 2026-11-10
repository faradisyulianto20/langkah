import 'package:flutter/foundation.dart';
import 'package:langkah/core/utils/date_helpers.dart';

/// Cermin enum Postgres `task_priority`.
enum TaskPriority {
  low('low', 'Rendah'),
  medium('medium', 'Sedang'),
  high('high', 'Tinggi');

  final String value;
  final String label;

  const TaskPriority(this.value, this.label);

  static TaskPriority fromValue(String? value) {
    for (final p in TaskPriority.values) {
      if (p.value == value) return p;
    }
    return TaskPriority.medium;
  }
}

/// Tugas harian dari tabel `daily_tasks`.
@immutable
class DailyTask {
  final String id;
  final String userId;
  final String? weeklyTargetId;
  final String? categoryId;
  final String title;
  final bool isCompleted;
  final DateTime scheduledDate;
  final TaskPriority priority;
  final DateTime? completedAt;
  final DateTime? createdAt;

  const DailyTask({
    required this.id,
    required this.userId,
    this.weeklyTargetId,
    this.categoryId,
    required this.title,
    this.isCompleted = false,
    required this.scheduledDate,
    this.priority = TaskPriority.medium,
    this.completedAt,
    this.createdAt,
  });

  DailyTask copyWith({
    String? id,
    String? userId,
    String? weeklyTargetId,
    String? categoryId,
    String? title,
    bool? isCompleted,
    DateTime? scheduledDate,
    TaskPriority? priority,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    DateTime? createdAt,
  }) {
    return DailyTask(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      weeklyTargetId: weeklyTargetId ?? this.weeklyTargetId,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      priority: priority ?? this.priority,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory DailyTask.fromMap(Map<String, dynamic> map) {
    return DailyTask(
      id: map['id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      weeklyTargetId: map['weekly_target_id'] as String?,
      categoryId: map['category_id'] as String?,
      title: map['title'] as String? ?? '',
      isCompleted: map['is_completed'] as bool? ?? false,
      scheduledDate:
          DateHelpers.parseSqlDate(map['scheduled_date']) ??
          DateHelpers.dateOnly(DateTime.now()),
      priority: TaskPriority.fromValue(map['priority'] as String?),
      completedAt: map['completed_at'] is String
          ? DateTime.tryParse(map['completed_at'] as String)
          : null,
      createdAt: map['created_at'] is String
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'weekly_target_id': weeklyTargetId,
      'category_id': categoryId,
      'title': title,
      'is_completed': isCompleted,
      'scheduled_date': DateHelpers.toSqlDate(scheduledDate),
      'priority': priority.value,
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyTask &&
          id == other.id &&
          userId == other.userId &&
          weeklyTargetId == other.weeklyTargetId &&
          categoryId == other.categoryId &&
          title == other.title &&
          isCompleted == other.isCompleted &&
          scheduledDate == other.scheduledDate &&
          priority == other.priority;

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    weeklyTargetId,
    categoryId,
    title,
    isCompleted,
    scheduledDate,
    priority,
  );
}
