import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:langkah/core/utils/completion_rules.dart';
import 'package:langkah/core/utils/date_helpers.dart';
import 'package:langkah/features/home/domain/daily_task.dart';
import 'package:langkah/features/planner/data/planner_repository.dart';
import 'package:langkah/features/planner/domain/backlog_item.dart';
import 'package:langkah/features/home/domain/category.dart';
import 'package:langkah/features/planner/domain/goal_status.dart';
import 'package:langkah/features/planner/domain/monthly_goal.dart';
import 'package:langkah/features/planner/domain/weekly_target.dart';

enum PlannerStatus { initial, loading, success, failure }

enum PlannerMode { weekly, monthly }

class PlannerViewModel extends ChangeNotifier {
  final PlannerRepository repository;

  /// [today] menetapkan hari acuan awal; bila [clock] tidak diberikan,
  /// [today] juga dipakai sebagai "sekarang" (berguna untuk tes).
  PlannerViewModel({
    required this.repository,
    DateTime? today,
    DateTime Function()? clock,
  }) : _clock = clock ?? (today != null ? (() => today) : DateTime.now),
       _focus = DateHelpers.dateOnly(
         today ?? (clock != null ? clock() : DateTime.now()),
       );

  final DateTime Function() _clock;
  DateTime get _now => _clock();

  PlannerStatus _status = PlannerStatus.initial;
  PlannerStatus _mutationStatus = PlannerStatus.initial;
  PlannerMode _mode = PlannerMode.weekly;
  DateTime _focus;
  int _loadToken = 0;
  DateTime? _selectedDay;

  List<MonthlyGoal> _goals = const [];
  List<WeeklyTarget> _weekTargets = const [];
  List<WeeklyTarget> _goalTargets = const [];
  List<DailyTask> _weekTasks = const [];
  List<BacklogItem> _backlog = const [];
  List<Category> _categories = const [];

  String? _errorMessage;
  String? _successMessage;

  // ───────────────────────── Getters ─────────────────────────

  PlannerStatus get status => _status;
  PlannerStatus get mutationStatus => _mutationStatus;
  PlannerMode get mode => _mode;
  DateTime get focusDate => _focus;
  bool get isLoading => _status == PlannerStatus.loading;
  bool get isMutating => _mutationStatus == PlannerStatus.loading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  List<MonthlyGoal> get goals => _goals;
  List<WeeklyTarget> get weekTargets => _weekTargets;
  List<DailyTask> get weekTasks => _weekTasks;
  List<BacklogItem> get backlog => _backlog;
  List<Category> get categories => _categories;

  DateTime get weekStart => DateHelpers.startOfWeek(_focus);
  DateTime get weekEnd => DateHelpers.endOfWeek(_focus);
  DateTime get month => DateHelpers.firstOfMonth(_focus);
  ({int year, int week}) get isoWeek => DateHelpers.isoWeek(_focus);

  List<DateTime> get weekDays => List.generate(
    7,
    (i) => DateTime(weekStart.year, weekStart.month, weekStart.day + i),
  );

  /// Baris 1 header periode. Contoh: `Minggu 46/53` atau `November 2026`.
  String get periodTitle => _mode == PlannerMode.weekly
      ? 'Minggu ${isoWeek.week}/${DateHelpers.isoWeeksInYear(isoWeek.year)}'
      : DateHelpers.monthLabel(_focus);

  /// Baris 2 header periode. Contoh: `9 Nov – 15 Nov` atau `Bulan 11/12`.
  String get periodSubtitle => _mode == PlannerMode.weekly
      ? DateHelpers.weekRangeLabel(weekStart)
      : 'Bulan ${_focus.month}/12';

  bool get isCurrentPeriod {
    final now = _now;
    return _mode == PlannerMode.weekly
        ? DateHelpers.isSameDay(DateHelpers.startOfWeek(now), weekStart)
        : now.year == _focus.year && now.month == _focus.month;
  }

  /// Hari yang sedang dipilih pada papan 7 hari. Default: hari ini bila
  /// berada di minggu aktif, selain itu Senin.
  DateTime get selectedDay {
    final picked = _selectedDay;
    if (picked != null &&
        !picked.isBefore(weekStart) &&
        !picked.isAfter(weekEnd)) {
      return picked;
    }
    final today = DateHelpers.dateOnly(_now);
    if (!today.isBefore(weekStart) && !today.isAfter(weekEnd)) return today;
    return weekStart;
  }

  void selectDay(DateTime day) {
    _selectedDay = DateHelpers.dateOnly(day);
    notifyListeners();
  }

  /// Progres tugas harian pada [day].
  ({int done, int total}) progressForDay(DateTime day) {
    final list = tasksForDay(day);
    return (done: list.where((t) => t.isCompleted).length, total: list.length);
  }

  /// Progres seluruh tugas harian minggu aktif.
  ({int done, int total}) get weekTaskProgress => (
    done: _weekTasks.where((t) => t.isCompleted).length,
    total: _weekTasks.length,
  );

  /// Progres target mingguan (selesai/total) pada minggu aktif.
  ({int done, int total}) get weekTargetProgress => (
    done: _weekTargets.where((t) => t.status == GoalStatus.completed).length,
    total: _weekTargets.length,
  );

  /// Progres sasaran bulanan (selesai/total) pada bulan aktif.
  ({int done, int total}) get monthGoalProgress => (
    done: _goals.where((g) => g.status == GoalStatus.completed).length,
    total: _goals.length,
  );

  /// Progres target mingguan yang tertaut ke sasaran bulan aktif.
  ({int done, int total}) get monthTargetProgress => (
    done: _goalTargets.where((t) => t.status == GoalStatus.completed).length,
    total: _goalTargets.length,
  );

  List<DailyTask> tasksForDay(DateTime day) => _weekTasks
      .where((t) => DateHelpers.isSameDay(t.scheduledDate, day))
      .toList();

  /// Tugas minggu ini yang tidak terhubung ke target mana pun.
  int get unlinkedTaskCount =>
      _weekTasks.where((t) => t.weeklyTargetId == null).length;

  Category? categoryById(String? id) {
    if (id == null) return null;
    for (final c in _categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  MonthlyGoal? goalById(String? id) {
    if (id == null) return null;
    for (final g in _goals) {
      if (g.id == id) return g;
    }
    return null;
  }

  /// Progres tugas harian yang berkontribusi ke sebuah target mingguan.
  ({int done, int total}) taskProgressForTarget(String targetId) {
    final linked = _weekTasks.where((t) => t.weeklyTargetId == targetId);
    return (
      done: linked.where((t) => t.isCompleted).length,
      total: linked.length,
    );
  }

  /// Progres target mingguan yang tertaut ke sebuah sasaran bulanan.
  ({int done, int total}) targetProgressForGoal(String goalId) {
    final linked = _goalTargets.where((t) => t.monthlyGoalId == goalId);
    return (
      done: linked.where((t) => t.status == GoalStatus.completed).length,
      total: linked.length,
    );
  }

  // ─────────── Aturan centang (hanya pada periodenya) ───────────

  bool canToggleTask(DailyTask t) =>
      CompletionRules.canCompleteTask(t.scheduledDate, _now);

  bool canToggleTarget(WeeklyTarget t) =>
      CompletionRules.canCompleteTarget(t.targetYear, t.targetWeek, _now);

  /// Apakah minggu yang sedang ditampilkan adalah minggu berjalan.
  bool get focusWeekIsCurrent =>
      CompletionRules.canCompleteTarget(isoWeek.year, isoWeek.week, _now);

  bool canToggleGoal(MonthlyGoal g) =>
      CompletionRules.canCompleteGoal(g.targetMonth, _now);

  /// Menolak aksi: simpan pesan dan beri tahu UI.
  bool _deny(String message) {
    _errorMessage = message;
    notifyListeners();
    return false;
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  // ───────────────────────── Navigasi ─────────────────────────

  Future<void> setMode(PlannerMode mode) {
    if (_mode == mode) return Future.value();
    _mode = mode;
    return load();
  }

  Future<void> goPrevious() => _shiftPeriod(-1);

  Future<void> goNext() => _shiftPeriod(1);

  Future<void> goToToday() {
    _focus = DateHelpers.dateOnly(_now);
    _selectedDay = null;
    return load();
  }

  Future<void> _shiftPeriod(int direction) {
    _selectedDay = null;
    _focus = _mode == PlannerMode.weekly
        ? DateTime(_focus.year, _focus.month, _focus.day + 7 * direction)
        : DateTime(_focus.year, _focus.month + direction, 1);
    return load();
  }

  // ───────────────────────── Load ─────────────────────────

  Future<void> load() async {
    final token = ++_loadToken;
    _status = PlannerStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final iso = isoWeek;
      final categoriesF = repository.getCategories();
      final backlogF = repository.getBacklog();
      final goalsF = repository.getMonthlyGoals(_focus);

      if (_mode == PlannerMode.weekly) {
        final targetsF = repository.getWeeklyTargets(iso.year, iso.week);
        final tasksF = repository.getDailyTasks(weekStart, weekEnd);
        final r = await Future.wait<Object?>([
          categoriesF,
          backlogF,
          goalsF,
          targetsF,
          tasksF,
        ]);
        if (token != _loadToken) return;
        _categories = r[0] as List<Category>;
        _backlog = r[1] as List<BacklogItem>;
        _goals = r[2] as List<MonthlyGoal>;
        _weekTargets = r[3] as List<WeeklyTarget>;
        _weekTasks = r[4] as List<DailyTask>;
      } else {
        final goalTargetsF = goalsF.then(
          (goals) =>
              repository.getTargetsForGoals(goals.map((g) => g.id).toList()),
        );
        final r = await Future.wait<Object?>([
          categoriesF,
          backlogF,
          goalsF,
          goalTargetsF,
        ]);
        if (token != _loadToken) return;
        _categories = r[0] as List<Category>;
        _backlog = r[1] as List<BacklogItem>;
        _goals = r[2] as List<MonthlyGoal>;
        _goalTargets = r[3] as List<WeeklyTarget>;
      }
      _status = PlannerStatus.success;
    } catch (e) {
      if (token != _loadToken) return;
      _status = PlannerStatus.failure;
      _errorMessage = _message(e);
    }
    notifyListeners();
  }

  // ───────────────────── Sasaran bulanan ─────────────────────

  Future<bool> addGoal({
    required String title,
    String? description,
    GoalStatus status = GoalStatus.pending,
  }) => _mutate(() async {
    final goal = await repository.addMonthlyGoal(
      title: title.trim(),
      description: _blankToNull(description),
      month: month,
      status: status,
    );
    _goals = [..._goals, goal];
  }, success: 'Sasaran bulanan ditambahkan.');

  Future<bool> updateGoal(
    MonthlyGoal goal, {
    required String title,
    String? description,
    required GoalStatus status,
  }) => _mutate(() async {
    final updated = await repository.updateMonthlyGoal(
      goal.copyWith(
        title: title.trim(),
        description: _blankToNull(description) ?? '',
        status: status,
      ),
    );
    _goals = [for (final g in _goals) g.id == goal.id ? updated : g];
  }, success: 'Sasaran diperbarui.');

  /// Centang cepat sasaran bulanan (optimistic, rollback bila gagal).
  Future<bool> toggleGoalCompleted(MonthlyGoal goal) async {
    if (!canToggleGoal(goal)) return _deny(CompletionRules.goalLockedMessage);
    final previous = _goals;
    final next = goal.status == GoalStatus.completed
        ? GoalStatus.pending
        : GoalStatus.completed;
    _goals = [
      for (final g in _goals)
        if (g.id == goal.id) g.copyWith(status: next) else g,
    ];
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await repository.updateMonthlyGoal(
        goal.copyWith(status: next),
      );
      _goals = [for (final g in _goals) g.id == goal.id ? updated : g];
      notifyListeners();
      return true;
    } catch (e) {
      _goals = previous;
      _errorMessage = _message(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteGoal(String id) => _mutate(() async {
    await repository.deleteMonthlyGoal(id);
    _goals = _goals.where((g) => g.id != id).toList();
    // DB mengubah monthly_goal_id target terkait menjadi NULL.
    _goalTargets = [
      for (final t in _goalTargets)
        if (t.monthlyGoalId == id) t.copyWith(clearMonthlyGoalId: true) else t,
    ];
    _weekTargets = [
      for (final t in _weekTargets)
        if (t.monthlyGoalId == id) t.copyWith(clearMonthlyGoalId: true) else t,
    ];
  }, success: 'Sasaran dihapus.');

  // ───────────────────── Target mingguan ─────────────────────

  Future<bool> addTarget({
    required String title,
    String? monthlyGoalId,
    GoalStatus status = GoalStatus.pending,
  }) async {
    if (status == GoalStatus.completed &&
        !CompletionRules.canCompleteTarget(isoWeek.year, isoWeek.week, _now)) {
      return _deny(CompletionRules.targetLockedMessage);
    }
    return _addTarget(title, monthlyGoalId, status);
  }

  Future<bool> _addTarget(
    String title,
    String? monthlyGoalId,
    GoalStatus status,
  ) => _mutate(() async {
    final iso = isoWeek;
    final target = await repository.addWeeklyTarget(
      title: title.trim(),
      year: iso.year,
      week: iso.week,
      monthlyGoalId: monthlyGoalId,
      status: status,
    );
    _weekTargets = [..._weekTargets, target];
  }, success: 'Target mingguan ditambahkan.');

  Future<bool> updateTarget(
    WeeklyTarget target, {
    required String title,
    String? monthlyGoalId,
    required GoalStatus status,
  }) async {
    final completionChanged =
        (status == GoalStatus.completed) !=
        (target.status == GoalStatus.completed);
    if (completionChanged && !canToggleTarget(target)) {
      return _deny(CompletionRules.targetLockedMessage);
    }
    return _updateTarget(target, title, monthlyGoalId, status);
  }

  Future<bool> _updateTarget(
    WeeklyTarget target,
    String title,
    String? monthlyGoalId,
    GoalStatus status,
  ) => _mutate(() async {
    final updated = await repository.updateWeeklyTarget(
      target.copyWith(
        title: title.trim(),
        monthlyGoalId: monthlyGoalId,
        clearMonthlyGoalId: monthlyGoalId == null,
        status: status,
      ),
    );
    _weekTargets = [
      for (final t in _weekTargets) t.id == target.id ? updated : t,
    ];
  }, success: 'Target diperbarui.');

  Future<bool> toggleTargetCompleted(WeeklyTarget target) {
    if (!canToggleTarget(target)) {
      return Future.value(_deny(CompletionRules.targetLockedMessage));
    }
    final next = target.status == GoalStatus.completed
        ? GoalStatus.pending
        : GoalStatus.completed;
    return updateTarget(
      target,
      title: target.title,
      monthlyGoalId: target.monthlyGoalId,
      status: next,
    );
  }

  Future<bool> deleteTarget(String id) => _mutate(() async {
    await repository.deleteWeeklyTarget(id);
    _weekTargets = _weekTargets.where((t) => t.id != id).toList();
    // DB mengubah weekly_target_id tugas terkait menjadi NULL.
    _weekTasks = [
      for (final t in _weekTasks)
        if (t.weeklyTargetId == id)
          DailyTask(
            id: t.id,
            userId: t.userId,
            categoryId: t.categoryId,
            title: t.title,
            isCompleted: t.isCompleted,
            scheduledDate: t.scheduledDate,
            priority: t.priority,
            completedAt: t.completedAt,
            createdAt: t.createdAt,
          )
        else
          t,
    ];
  }, success: 'Target dihapus.');

  // ───────────────────── Tugas harian ─────────────────────

  Future<bool> addTask({
    required String title,
    required DateTime date,
    TaskPriority priority = TaskPriority.medium,
    String? categoryId,
    String? weeklyTargetId,
  }) => _mutate(() async {
    final task = await repository.addDailyTask(
      title: title.trim(),
      date: DateHelpers.dateOnly(date),
      priority: priority,
      categoryId: categoryId,
      weeklyTargetId: weeklyTargetId,
    );
    if (_inLoadedWeek(task.scheduledDate)) {
      _weekTasks = [..._weekTasks, task];
    }
  }, success: 'Tugas ditambahkan.');

  /// Optimistic update dengan rollback bila gagal.
  Future<bool> toggleTask(DailyTask task) async {
    if (!canToggleTask(task)) return _deny(CompletionRules.taskLockedMessage);
    final previous = _weekTasks;
    final nextCompleted = !task.isCompleted;
    _weekTasks = [
      for (final t in _weekTasks)
        if (t.id == task.id)
          t.copyWith(
            isCompleted: nextCompleted,
            completedAt: nextCompleted ? _now : null,
            clearCompletedAt: !nextCompleted,
          )
        else
          t,
    ];
    _errorMessage = null;
    notifyListeners();

    try {
      await repository.setTaskCompleted(task.id, nextCompleted);
      return true;
    } catch (e) {
      _weekTasks = previous;
      _errorMessage = _message(e);
      notifyListeners();
      return false;
    }
  }

  /// Edit rencana tugas (judul, hari, prioritas, kategori, target).
  /// Status selesai tidak diubah di sini.
  Future<bool> updateTask(
    DailyTask task, {
    required String title,
    required DateTime date,
    required TaskPriority priority,
    String? categoryId,
    String? weeklyTargetId,
  }) => _mutate(() async {
    final updated = await repository.updateDailyTask(
      DailyTask(
        id: task.id,
        userId: task.userId,
        title: title.trim(),
        scheduledDate: DateHelpers.dateOnly(date),
        priority: priority,
        categoryId: categoryId,
        weeklyTargetId: weeklyTargetId,
        isCompleted: task.isCompleted,
        completedAt: task.completedAt,
        createdAt: task.createdAt,
      ),
    );
    final rest = _weekTasks.where((t) => t.id != task.id).toList();
    _weekTasks = _inLoadedWeek(updated.scheduledDate)
        ? [...rest, updated]
        : rest;
  }, success: 'Tugas diperbarui.');

  Future<bool> deleteTask(String id) => _mutate(() async {
    await repository.deleteDailyTask(id);
    _weekTasks = _weekTasks.where((t) => t.id != id).toList();
  }, success: 'Tugas dihapus.');

  // ───────────────────────── Backlog ─────────────────────────

  Future<bool> addBacklog({
    required String title,
    String? notes,
    String? categoryId,
  }) => _mutate(() async {
    final item = await repository.addBacklogItem(
      title: title.trim(),
      notes: _blankToNull(notes),
      categoryId: categoryId,
    );
    _backlog = [item, ..._backlog];
  }, success: 'Ditambahkan ke backlog.');

  Future<bool> deleteBacklog(String id) => _mutate(() async {
    await repository.deleteBacklogItem(id);
    _backlog = _backlog.where((b) => b.id != id).toList();
  }, success: 'Item backlog dihapus.');

  Future<bool> scheduleBacklog(BacklogItem item, DateTime date) =>
      _mutate(() async {
        final task = await repository.scheduleBacklogItem(
          item,
          DateHelpers.dateOnly(date),
        );
        _backlog = _backlog.where((b) => b.id != item.id).toList();
        if (_inLoadedWeek(task.scheduledDate)) {
          _weekTasks = [..._weekTasks, task];
        }
      }, success: 'Dijadwalkan ke ${DateHelpers.shortDate(date)}.');

  // ───────────────────────── Internal ─────────────────────────

  bool _inLoadedWeek(DateTime date) =>
      _mode == PlannerMode.weekly &&
      !date.isBefore(weekStart) &&
      !date.isAfter(weekEnd);

  Future<bool> _mutate(
    Future<void> Function() action, {
    required String success,
  }) async {
    _mutationStatus = PlannerStatus.loading;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await action();
      _mutationStatus = PlannerStatus.success;
      _successMessage = success;
      notifyListeners();
      return true;
    } catch (e) {
      _mutationStatus = PlannerStatus.failure;
      _errorMessage = _message(e);
      notifyListeners();
      return false;
    }
  }

  String _message(Object e) => e.toString().replaceFirst('Exception: ', '');

  String? _blankToNull(String? value) {
    final v = value?.trim();
    return (v == null || v.isEmpty) ? null : v;
  }
}
