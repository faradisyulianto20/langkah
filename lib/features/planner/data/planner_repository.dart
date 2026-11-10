import 'package:langkah/features/home/domain/daily_task.dart';
import 'package:langkah/features/planner/domain/backlog_item.dart';
import 'package:langkah/features/home/domain/category.dart';
import 'package:langkah/features/planner/domain/goal_status.dart';
import 'package:langkah/features/planner/domain/monthly_goal.dart';
import 'package:langkah/features/planner/domain/weekly_target.dart';

abstract class PlannerRepository {
  // Read
  Future<List<Category>> getCategories();
  Future<List<MonthlyGoal>> getMonthlyGoals(DateTime month);
  Future<List<WeeklyTarget>> getWeeklyTargets(int year, int week);
  Future<List<WeeklyTarget>> getTargetsForGoals(List<String> goalIds);
  Future<List<DailyTask>> getDailyTasks(DateTime from, DateTime to);
  Future<List<BacklogItem>> getBacklog();

  // Monthly goals
  Future<MonthlyGoal> addMonthlyGoal({
    required String title,
    String? description,
    required DateTime month,
    GoalStatus status = GoalStatus.pending,
  });
  Future<MonthlyGoal> updateMonthlyGoal(MonthlyGoal goal);
  Future<void> deleteMonthlyGoal(String id);

  // Weekly targets
  Future<WeeklyTarget> addWeeklyTarget({
    required String title,
    required int year,
    required int week,
    String? monthlyGoalId,
    GoalStatus status = GoalStatus.pending,
  });
  Future<WeeklyTarget> updateWeeklyTarget(WeeklyTarget target);
  Future<void> deleteWeeklyTarget(String id);

  // Daily tasks
  Future<DailyTask> addDailyTask({
    required String title,
    required DateTime date,
    TaskPriority priority = TaskPriority.medium,
    String? categoryId,
    String? weeklyTargetId,
  });
  Future<DailyTask> updateDailyTask(DailyTask task);
  Future<void> setTaskCompleted(String id, bool completed);
  Future<void> deleteDailyTask(String id);

  // Backlog
  Future<BacklogItem> addBacklogItem({
    required String title,
    String? notes,
    String? categoryId,
  });
  Future<void> deleteBacklogItem(String id);

  /// Menjadikan item backlog sebagai tugas harian di [date], lalu
  /// menghapus item dari backlog.
  Future<DailyTask> scheduleBacklogItem(BacklogItem item, DateTime date);
}
