import 'package:flutter/foundation.dart' show debugPrint;
import 'package:langkah/core/network/supabase_config.dart';
import 'package:langkah/core/utils/date_helpers.dart';
import 'package:langkah/features/home/domain/daily_task.dart';
import 'package:langkah/features/planner/data/planner_repository.dart';
import 'package:langkah/features/planner/domain/backlog_item.dart';
import 'package:langkah/features/planner/domain/category.dart';
import 'package:langkah/features/planner/domain/goal_status.dart';
import 'package:langkah/features/planner/domain/monthly_goal.dart';
import 'package:langkah/features/planner/domain/weekly_target.dart';

class PlannerRepositoryImpl implements PlannerRepository {
  String get _uid {
    final id = SupabaseConfig.client.auth.currentUser?.id;
    if (id == null) {
      throw Exception('Sesi berakhir. Silakan login ulang.');
    }
    return id;
  }

  // ───────────────────────── Read ─────────────────────────

  @override
  Future<List<Category>> getCategories() => _guard(() async {
    final rows = await SupabaseConfig.client
        .from('categories')
        .select()
        .eq('user_id', _uid)
        .order('created_at');
    return rows.map(Category.fromMap).toList();
  });

  @override
  Future<List<MonthlyGoal>> getMonthlyGoals(DateTime month) => _guard(() async {
    final rows = await SupabaseConfig.client
        .from('monthly_goals')
        .select()
        .eq('user_id', _uid)
        .eq(
          'target_month',
          DateHelpers.toSqlDate(DateHelpers.firstOfMonth(month)),
        )
        .order('created_at');
    return rows.map(MonthlyGoal.fromMap).toList();
  });

  @override
  Future<List<WeeklyTarget>> getWeeklyTargets(int year, int week) =>
      _guard(() async {
        final rows = await SupabaseConfig.client
            .from('weekly_targets')
            .select()
            .eq('user_id', _uid)
            .eq('target_year', year)
            .eq('target_week', week)
            .order('created_at');
        return rows.map(WeeklyTarget.fromMap).toList();
      });

  @override
  Future<List<WeeklyTarget>> getTargetsForGoals(List<String> goalIds) {
    if (goalIds.isEmpty) return Future.value(const []);
    return _guard(() async {
      final rows = await SupabaseConfig.client
          .from('weekly_targets')
          .select()
          .eq('user_id', _uid)
          .inFilter('monthly_goal_id', goalIds)
          .order('target_year')
          .order('target_week');
      return rows.map(WeeklyTarget.fromMap).toList();
    });
  }

  @override
  Future<List<DailyTask>> getDailyTasks(DateTime from, DateTime to) =>
      _guard(() async {
        final rows = await SupabaseConfig.client
            .from('daily_tasks')
            .select()
            .eq('user_id', _uid)
            .gte('scheduled_date', DateHelpers.toSqlDate(from))
            .lte('scheduled_date', DateHelpers.toSqlDate(to))
            .order('created_at');
        return rows.map(DailyTask.fromMap).toList();
      });

  @override
  Future<List<BacklogItem>> getBacklog() => _guard(() async {
    final rows = await SupabaseConfig.client
        .from('backlog_items')
        .select()
        .eq('user_id', _uid)
        .order('created_at', ascending: false);
    return rows.map(BacklogItem.fromMap).toList();
  });

  // ─────────────────────── Monthly goals ───────────────────────

  @override
  Future<MonthlyGoal> addMonthlyGoal({
    required String title,
    String? description,
    required DateTime month,
    GoalStatus status = GoalStatus.pending,
  }) => _guard(() async {
    final row = await SupabaseConfig.client
        .from('monthly_goals')
        .insert({
          'user_id': _uid,
          'title': title,
          'description': description,
          'target_month': DateHelpers.toSqlDate(
            DateHelpers.firstOfMonth(month),
          ),
          'status': status.value,
        })
        .select()
        .single();
    return MonthlyGoal.fromMap(row);
  });

  @override
  Future<MonthlyGoal> updateMonthlyGoal(MonthlyGoal goal) => _guard(() async {
    final row = await SupabaseConfig.client
        .from('monthly_goals')
        .update({
          'title': goal.title,
          'description': goal.description,
          'status': goal.status.value,
        })
        .eq('id', goal.id)
        .select()
        .single();
    return MonthlyGoal.fromMap(row);
  });

  @override
  Future<void> deleteMonthlyGoal(String id) => _guard(() async {
    await SupabaseConfig.client.from('monthly_goals').delete().eq('id', id);
  });

  // ─────────────────────── Weekly targets ───────────────────────

  @override
  Future<WeeklyTarget> addWeeklyTarget({
    required String title,
    required int year,
    required int week,
    String? monthlyGoalId,
    GoalStatus status = GoalStatus.pending,
  }) => _guard(() async {
    final row = await SupabaseConfig.client
        .from('weekly_targets')
        .insert({
          'user_id': _uid,
          'monthly_goal_id': monthlyGoalId,
          'title': title,
          'target_year': year,
          'target_week': week,
          'status': status.value,
        })
        .select()
        .single();
    return WeeklyTarget.fromMap(row);
  });

  @override
  Future<WeeklyTarget> updateWeeklyTarget(WeeklyTarget target) =>
      _guard(() async {
        final row = await SupabaseConfig.client
            .from('weekly_targets')
            .update({
              'title': target.title,
              'monthly_goal_id': target.monthlyGoalId,
              'status': target.status.value,
            })
            .eq('id', target.id)
            .select()
            .single();
        return WeeklyTarget.fromMap(row);
      });

  @override
  Future<void> deleteWeeklyTarget(String id) => _guard(() async {
    await SupabaseConfig.client.from('weekly_targets').delete().eq('id', id);
  });

  // ─────────────────────── Daily tasks ───────────────────────

  @override
  Future<DailyTask> addDailyTask({
    required String title,
    required DateTime date,
    TaskPriority priority = TaskPriority.medium,
    String? categoryId,
    String? weeklyTargetId,
  }) => _guard(() async {
    final row = await SupabaseConfig.client
        .from('daily_tasks')
        .insert({
          'user_id': _uid,
          'title': title,
          'scheduled_date': DateHelpers.toSqlDate(date),
          'priority': priority.value,
          'category_id': categoryId,
          'weekly_target_id': weeklyTargetId,
        })
        .select()
        .single();
    return DailyTask.fromMap(row);
  });

  @override
  Future<void> setTaskCompleted(String id, bool completed) => _guard(() async {
    await SupabaseConfig.client
        .from('daily_tasks')
        .update({
          'is_completed': completed,
          'completed_at': completed
              ? DateTime.now().toUtc().toIso8601String()
              : null,
        })
        .eq('id', id);
  });

  @override
  Future<void> deleteDailyTask(String id) => _guard(() async {
    await SupabaseConfig.client.from('daily_tasks').delete().eq('id', id);
  });

  // ───────────────────────── Backlog ─────────────────────────

  @override
  Future<BacklogItem> addBacklogItem({
    required String title,
    String? notes,
    String? categoryId,
  }) => _guard(() async {
    final row = await SupabaseConfig.client
        .from('backlog_items')
        .insert({
          'user_id': _uid,
          'title': title,
          'notes': notes,
          'category_id': categoryId,
        })
        .select()
        .single();
    return BacklogItem.fromMap(row);
  });

  @override
  Future<void> deleteBacklogItem(String id) => _guard(() async {
    await SupabaseConfig.client.from('backlog_items').delete().eq('id', id);
  });

  @override
  Future<DailyTask> scheduleBacklogItem(BacklogItem item, DateTime date) async {
    // Insert dulu: bila gagal, item backlog tetap aman.
    final task = await addDailyTask(
      title: item.title,
      date: date,
      categoryId: item.categoryId,
    );
    try {
      await deleteBacklogItem(item.id);
    } catch (_) {
      // Tugas sudah terbuat; rollback agar tidak ada duplikat.
      try {
        await deleteDailyTask(task.id);
      } catch (e) {
        debugPrint('[PlannerRepository] rollback gagal: $e');
      }
      rethrow;
    }
    return task;
  }

  // ───────────────────────── Error ─────────────────────────

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(Object e) {
    if (e is Exception && e.toString().contains('Sesi berakhir')) return e;
    final message = e.toString();
    debugPrint('[PlannerRepository] ${e.runtimeType}: $message');
    if (message.contains('row-level security') ||
        message.contains('permission denied')) {
      return Exception('Akses ditolak. Silakan login ulang.');
    }
    if (message.contains('SocketException') ||
        message.contains('ClientException') ||
        message.contains('connection') ||
        message.contains('network')) {
      return Exception(
        'Gagal terhubung ke server. Periksa koneksi internet Anda.',
      );
    }
    return Exception('Terjadi kesalahan. Silakan coba lagi.');
  }
}
