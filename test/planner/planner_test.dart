import 'package:flutter_test/flutter_test.dart';
import 'package:langkah/core/utils/date_helpers.dart';
import 'package:langkah/features/home/domain/daily_task.dart';
import 'package:langkah/features/planner/data/planner_repository.dart';
import 'package:langkah/features/planner/domain/backlog_item.dart';
import 'package:langkah/features/planner/domain/category.dart';
import 'package:langkah/features/planner/domain/goal_status.dart';
import 'package:langkah/features/planner/domain/monthly_goal.dart';
import 'package:langkah/features/planner/domain/weekly_target.dart';
import 'package:langkah/features/planner/presentation/planner_view_model.dart';

/// Repository palsu di memori.
class FakeRepo implements PlannerRepository {
  bool fail = false;
  int _n = 0;
  final goals = <MonthlyGoal>[];
  final targets = <WeeklyTarget>[];
  final tasks = <DailyTask>[];
  final backlog = <BacklogItem>[];

  String _id() => 'id${_n++}';
  void _check() {
    if (fail) throw Exception('Terjadi kesalahan. Silakan coba lagi.');
  }

  @override
  Future<List<Category>> getCategories() async => const [];
  @override
  Future<List<MonthlyGoal>> getMonthlyGoals(DateTime month) async {
    _check();
    return List.of(goals);
  }

  @override
  Future<List<WeeklyTarget>> getWeeklyTargets(int year, int week) async {
    _check();
    return targets
        .where((t) => t.targetYear == year && t.targetWeek == week)
        .toList();
  }

  @override
  Future<List<WeeklyTarget>> getTargetsForGoals(List<String> ids) async =>
      targets.where((t) => ids.contains(t.monthlyGoalId)).toList();
  @override
  Future<List<DailyTask>> getDailyTasks(DateTime from, DateTime to) async =>
      List.of(tasks);
  @override
  Future<List<BacklogItem>> getBacklog() async => List.of(backlog);

  @override
  Future<MonthlyGoal> addMonthlyGoal({
    required String title,
    String? description,
    required DateTime month,
    GoalStatus status = GoalStatus.pending,
  }) async {
    _check();
    final g = MonthlyGoal(
      id: _id(),
      userId: 'u',
      title: title,
      description: description,
      targetMonth: month,
      status: status,
    );
    goals.add(g);
    return g;
  }

  @override
  Future<MonthlyGoal> updateMonthlyGoal(MonthlyGoal goal) async {
    _check();
    return goal;
  }

  @override
  Future<void> deleteMonthlyGoal(String id) async =>
      goals.removeWhere((g) => g.id == id);

  @override
  Future<WeeklyTarget> addWeeklyTarget({
    required String title,
    required int year,
    required int week,
    String? monthlyGoalId,
    GoalStatus status = GoalStatus.pending,
  }) async {
    _check();
    final t = WeeklyTarget(
      id: _id(),
      userId: 'u',
      title: title,
      targetWeek: week,
      targetYear: year,
      monthlyGoalId: monthlyGoalId,
      status: status,
    );
    targets.add(t);
    return t;
  }

  @override
  Future<WeeklyTarget> updateWeeklyTarget(WeeklyTarget target) async {
    _check();
    return target;
  }

  @override
  Future<void> deleteWeeklyTarget(String id) async =>
      targets.removeWhere((t) => t.id == id);

  @override
  Future<DailyTask> addDailyTask({
    required String title,
    required DateTime date,
    TaskPriority priority = TaskPriority.medium,
    String? categoryId,
    String? weeklyTargetId,
  }) async {
    _check();
    final t = DailyTask(
      id: _id(),
      userId: 'u',
      title: title,
      scheduledDate: date,
      priority: priority,
      weeklyTargetId: weeklyTargetId,
    );
    tasks.add(t);
    return t;
  }

  @override
  Future<void> setTaskCompleted(String id, bool completed) async => _check();
  @override
  Future<void> deleteDailyTask(String id) async =>
      tasks.removeWhere((t) => t.id == id);

  @override
  Future<BacklogItem> addBacklogItem({
    required String title,
    String? notes,
    String? categoryId,
  }) async {
    final b = BacklogItem(id: _id(), userId: 'u', title: title);
    backlog.add(b);
    return b;
  }

  @override
  Future<void> deleteBacklogItem(String id) async =>
      backlog.removeWhere((b) => b.id == id);

  @override
  Future<DailyTask> scheduleBacklogItem(BacklogItem item, DateTime date) async {
    final t = await addDailyTask(title: item.title, date: date);
    backlog.removeWhere((b) => b.id == item.id);
    return t;
  }
}

void main() {
  group('DateHelpers', () {
    test('isoWeek menangani batas tahun', () {
      expect(DateHelpers.isoWeek(DateTime(2026, 1, 1)), (year: 2026, week: 1));
      expect(DateHelpers.isoWeek(DateTime(2024, 12, 30)), (
        year: 2025,
        week: 1,
      ));
      expect(DateHelpers.isoWeek(DateTime(2021, 1, 3)), (year: 2020, week: 53));
    });

    test('isoWeeksInYear', () {
      expect(DateHelpers.isoWeeksInYear(2026), 53);
      expect(DateHelpers.isoWeeksInYear(2025), 52);
      expect(DateHelpers.isoWeeksInYear(2020), 53);
    });

    test('startOfWeek mengembalikan Senin & toSqlDate padded', () {
      // 2026-11-10 adalah Selasa.
      expect(
        DateHelpers.startOfWeek(DateTime(2026, 11, 10)),
        DateTime(2026, 11, 9),
      );
      expect(DateHelpers.toSqlDate(DateTime(2026, 3, 5)), '2026-03-05');
    });
  });

  group('Model', () {
    test('fromMap aman terhadap null & round-trip', () {
      final g = MonthlyGoal.fromMap({'id': 'a', 'status': 'in_progress'});
      expect(g.title, '');
      expect(g.status, GoalStatus.inProgress);

      final t = DailyTask.fromMap({
        'id': 't',
        'title': 'x',
        'scheduled_date': '2026-11-10',
        'priority': 'high',
      });
      expect(DailyTask.fromMap(t.toMap()), t);
      expect(WeeklyTarget.fromMap(const {}).status, GoalStatus.pending);
    });

    test('Category.color fallback bila hex tidak valid', () {
      expect(
        const Category(
          id: '1',
          userId: 'u',
          name: 'n',
          colorHex: 'zz',
        ).color.toARGB32(),
        0xFF00897B,
      );
      expect(
        const Category(
          id: '1',
          userId: 'u',
          name: 'n',
          colorHex: '#FB8C00',
        ).color.toARGB32(),
        0xFFFB8C00,
      );
    });
  });

  group('PlannerViewModel', () {
    late FakeRepo repo;
    late PlannerViewModel vm;

    setUp(() {
      repo = FakeRepo();
      vm = PlannerViewModel(repository: repo, today: DateTime(2026, 11, 10));
    });

    test('load sukses', () async {
      await vm.load();
      expect(vm.status, PlannerStatus.success);
      expect(vm.weekDays.length, 7);
    });

    test('load gagal menyimpan pesan error', () async {
      repo.fail = true;
      await vm.load();
      expect(vm.status, PlannerStatus.failure);
      expect(vm.errorMessage, 'Terjadi kesalahan. Silakan coba lagi.');
    });

    test('tambah target + tugas terhubung menghitung progres', () async {
      await vm.load();
      await vm.addTarget(title: 'T1');
      final target = vm.weekTargets.single;
      await vm.addTask(
        title: 'a',
        date: DateTime(2026, 11, 10),
        weeklyTargetId: target.id,
      );
      await vm.addTask(title: 'b', date: DateTime(2026, 11, 11));

      expect(vm.taskProgressForTarget(target.id), (done: 0, total: 1));
      expect(vm.unlinkedTaskCount, 1);

      await vm.toggleTask(vm.weekTasks.first);
      expect(vm.taskProgressForTarget(target.id), (done: 1, total: 1));
    });

    test('toggleTask rollback saat gagal', () async {
      await vm.load();
      await vm.addTask(title: 'a', date: DateTime(2026, 11, 10));
      repo.fail = true;
      final ok = await vm.toggleTask(vm.weekTasks.single);
      expect(ok, isFalse);
      expect(vm.weekTasks.single.isCompleted, isFalse);
    });

    test('tugas di luar minggu aktif tidak masuk list lokal', () async {
      await vm.load();
      await vm.addTask(title: 'x', date: DateTime(2026, 12, 25));
      expect(vm.weekTasks, isEmpty);
    });

    test('scheduleBacklog menghapus item & membuat tugas', () async {
      await vm.load();
      await vm.addBacklog(title: 'ide');
      final item = vm.backlog.single;
      await vm.scheduleBacklog(item, DateTime(2026, 11, 12));
      expect(vm.backlog, isEmpty);
      expect(vm.weekTasks.single.title, 'ide');
    });

    test('hapus target melepas tautan tugas', () async {
      await vm.load();
      await vm.addTarget(title: 'T');
      final id = vm.weekTargets.single.id;
      await vm.addTask(
        title: 'a',
        date: DateTime(2026, 11, 10),
        weeklyTargetId: id,
      );
      await vm.deleteTarget(id);
      expect(vm.weekTargets, isEmpty);
      expect(vm.weekTasks.single.weeklyTargetId, isNull);
    });

    test('judul periode 2 baris dengan x/y', () async {
      expect(vm.periodTitle, 'Minggu 46/53');
      expect(vm.periodSubtitle, '9 Nov – 15 Nov');
      await vm.setMode(PlannerMode.monthly);
      expect(vm.periodTitle, 'November 2026');
      expect(vm.periodSubtitle, 'Bulan 11/12');
    });

    test('selectDay & progres per hari/minggu', () async {
      await vm.load();
      await vm.goNext(); // minggu 16-22 Nov, bukan minggu sistem
      expect(vm.selectedDay, vm.weekStart);
      vm.selectDay(DateTime(2026, 11, 18));
      expect(vm.selectedDay, DateTime(2026, 11, 18));

      await vm.addTask(title: 'a', date: DateTime(2026, 11, 18));
      await vm.addTask(title: 'b', date: DateTime(2026, 11, 18));
      await vm.toggleTask(vm.weekTasks.first);
      expect(vm.progressForDay(DateTime(2026, 11, 18)), (done: 1, total: 2));
      expect(vm.weekTaskProgress, (done: 1, total: 2));

      await vm.goNext(); // pilihan direset ke Senin minggu baru
      expect(vm.selectedDay, vm.weekStart);
    });

    test('centang sasaran bulanan: optimistic & rollback', () async {
      await vm.setMode(PlannerMode.monthly);
      await vm.addGoal(title: 'G');
      expect(vm.monthGoalProgress, (done: 0, total: 1));

      expect(await vm.toggleGoalCompleted(vm.goals.single), isTrue);
      expect(vm.goals.single.status, GoalStatus.completed);
      expect(vm.monthGoalProgress, (done: 1, total: 1));

      repo.fail = true;
      expect(await vm.toggleGoalCompleted(vm.goals.single), isFalse);
      expect(vm.goals.single.status, GoalStatus.completed); // rollback
    });

    test('navigasi minggu & bulan', () async {
      await vm.load();
      await vm.goNext();
      expect(vm.weekStart, DateTime(2026, 11, 16));
      expect(vm.isCurrentPeriod, isFalse);
      await vm.setMode(PlannerMode.monthly);
      await vm.goPrevious();
      expect(vm.month, DateTime(2026, 10, 1));
    });

    test('progres sasaran bulanan dari target selesai', () async {
      await vm.setMode(PlannerMode.monthly);
      await vm.addGoal(title: 'G');
      final gid = vm.goals.single.id;
      repo.targets.addAll([
        WeeklyTarget(
          id: 'a',
          userId: 'u',
          title: 'a',
          targetWeek: 45,
          targetYear: 2026,
          monthlyGoalId: gid,
          status: GoalStatus.completed,
        ),
        WeeklyTarget(
          id: 'b',
          userId: 'u',
          title: 'b',
          targetWeek: 46,
          targetYear: 2026,
          monthlyGoalId: gid,
        ),
      ]);
      await vm.load();
      expect(vm.targetProgressForGoal(gid), (done: 1, total: 2));
    });
  });
}
