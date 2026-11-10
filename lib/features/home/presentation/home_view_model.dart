import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:langkah/core/utils/completion_rules.dart';
import 'package:langkah/core/utils/date_helpers.dart';
import 'package:langkah/features/home/data/home_repository.dart';
import 'package:langkah/features/home/domain/category.dart';
import 'package:langkah/features/home/domain/daily_task.dart';
import 'package:langkah/features/settings/domain/profile_model.dart';
import 'package:langkah/features/settings/domain/streak_data.dart';

enum HomeStatus { initial, loading, success, failure }

/// Tujuan penyimpanan di quick add.
enum QuickAddTarget { today, backlog }

class HomeViewModel extends ChangeNotifier {
  final HomeRepository repository;
  final DateTime Function() _clock;

  HomeViewModel({required this.repository, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  HomeStatus _status = HomeStatus.initial;
  HomeStatus _mutationStatus = HomeStatus.initial;
  int _loadToken = 0;

  List<DailyTask> _tasks = const [];
  List<Category> _categories = const [];
  StreakData? _stats;
  ProfileModel? _profile;
  String? _filterCategoryId;
  DateTime? _loadedDay;

  String? _errorMessage;
  String? _successMessage;

  // ───────────────────────── Getters ─────────────────────────

  HomeStatus get status => _status;
  bool get isLoading => _status == HomeStatus.loading;
  bool get isMutating => _mutationStatus == HomeStatus.loading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  List<DailyTask> get tasks => _tasks;
  List<Category> get categories => _categories;

  /// Profil (nama & foto) untuk avatar; null bila belum/gagal dimuat.
  ProfileModel? get profile => _profile;
  String? get filterCategoryId => _filterCategoryId;

  DateTime get today => DateHelpers.dateOnly(_clock());

  /// Streak yang ditampilkan (0 bila sudah putus).
  int get streak => _stats?.effectiveCurrentStreak(_clock()) ?? 0;

  List<DailyTask> get _filtered => _filterCategoryId == null
      ? _tasks
      : _tasks.where((t) => t.categoryId == _filterCategoryId).toList();

  List<DailyTask> get pendingTasks =>
      _filtered.where((t) => !t.isCompleted).toList();

  List<DailyTask> get doneTasks =>
      _filtered.where((t) => t.isCompleted).toList();

  /// Progres seluruh tugas hari ini (tidak terpengaruh filter kategori).
  ({int done, int total}) get progress =>
      (done: _tasks.where((t) => t.isCompleted).length, total: _tasks.length);

  /// Hanya tugas milik hari ini yang bisa dicentang.
  bool canToggle(DailyTask t) =>
      CompletionRules.canCompleteTask(t.scheduledDate, _clock());

  Category? categoryById(String? id) {
    if (id == null) return null;
    for (final c in _categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  DailyTask? taskById(String? id) {
    if (id == null) return null;
    for (final t in _tasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void setFilter(String? categoryId) {
    if (_filterCategoryId == categoryId) return;
    _filterCategoryId = categoryId;
    notifyListeners();
  }

  // ───────────────────────── Load ─────────────────────────

  Future<void> load() async {
    final token = ++_loadToken;
    final day = today;
    _status = HomeStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final r = await Future.wait<Object?>([
        repository.getTasksForDay(day),
        repository.getCategories(),
        repository.getStats(),
        // Profil hanya pelengkap: kegagalannya tidak menggagalkan Home.
        repository
            .getProfile()
            .then<ProfileModel?>((p) => p)
            .catchError((Object _) => null),
      ]);
      if (token != _loadToken) return;
      _tasks = r[0] as List<DailyTask>;
      _categories = r[1] as List<Category>;
      _stats = r[2] as StreakData;
      _profile = (r[3] as ProfileModel?) ?? _profile;
      _loadedDay = day;
      if (_filterCategoryId != null &&
          !_categories.any((c) => c.id == _filterCategoryId)) {
        _filterCategoryId = null;
      }
      _status = HomeStatus.success;
    } catch (e) {
      if (token != _loadToken) return;
      _status = HomeStatus.failure;
      _errorMessage = _message(e);
    }
    notifyListeners();
  }

  /// true bila hari sudah berganti sejak data terakhir dimuat.
  bool get isStale =>
      _loadedDay != null && !DateHelpers.isSameDay(_loadedDay!, _clock());

  // ───────────────────────── Aksi ─────────────────────────

  /// Optimistic update; rollback bila gagal. Streak ikut diperbarui.
  Future<bool> toggleTask(DailyTask task) async {
    if (!canToggle(task)) {
      _errorMessage = CompletionRules.taskLockedMessage;
      notifyListeners();
      return false;
    }
    final previous = _tasks;
    final next = !task.isCompleted;
    _tasks = [
      for (final t in _tasks)
        if (t.id == task.id)
          t.copyWith(
            isCompleted: next,
            completedAt: next ? _clock() : null,
            clearCompletedAt: !next,
          )
        else
          t,
    ];
    _errorMessage = null;
    notifyListeners();

    try {
      final stats = await repository.setTaskCompleted(task.id, next);
      if (stats != null) {
        _stats = stats;
      } else {
        // Sinkron streak gagal: ambil ulang agar tampilan tetap benar.
        _refreshStats();
      }
      notifyListeners();
      return true;
    } catch (e) {
      _tasks = previous;
      _errorMessage = _message(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> _refreshStats() async {
    try {
      _stats = await repository.getStats();
      notifyListeners();
    } catch (_) {
      // Abaikan: tampilan streak lama tetap dipakai.
    }
  }

  /// Quick add. Untuk [QuickAddTarget.backlog] prioritas diabaikan.
  Future<bool> quickAdd({
    required String title,
    required QuickAddTarget target,
    TaskPriority priority = TaskPriority.medium,
    String? categoryId,
  }) => _mutate(
    () async {
      if (target == QuickAddTarget.today) {
        final task = await repository.addTask(
          title: title.trim(),
          date: today,
          priority: priority,
          categoryId: categoryId,
        );
        _tasks = [..._tasks, task];
      } else {
        await repository.addBacklogItem(
          title: title.trim(),
          categoryId: categoryId,
        );
      }
    },
    success: target == QuickAddTarget.today
        ? 'Langkah ditambahkan ke hari ini.'
        : 'Dilempar ke Backlog di Planner.',
  );

  /// Edit judul, prioritas, kategori. Status selesai tidak berubah.
  Future<bool> updateTask(
    DailyTask task, {
    required String title,
    required TaskPriority priority,
    String? categoryId,
  }) => _mutate(() async {
    final updated = await repository.updateTask(
      DailyTask(
        id: task.id,
        userId: task.userId,
        weeklyTargetId: task.weeklyTargetId,
        categoryId: categoryId,
        title: title.trim(),
        isCompleted: task.isCompleted,
        scheduledDate: task.scheduledDate,
        priority: priority,
        completedAt: task.completedAt,
        createdAt: task.createdAt,
      ),
    );
    _tasks = [for (final t in _tasks) t.id == task.id ? updated : t];
  }, success: 'Langkah diperbarui.');

  Future<bool> deleteTask(DailyTask task) => _mutate(() async {
    await repository.deleteTask(task.id);
    _tasks = _tasks.where((t) => t.id != task.id).toList();
    // Menghapus tugas selesai tidak memundurkan streak/total (riwayat).
  }, success: 'Langkah dihapus.');

  Future<bool> _mutate(
    Future<void> Function() action, {
    required String success,
  }) async {
    _mutationStatus = HomeStatus.loading;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await action();
      _mutationStatus = HomeStatus.success;
      _successMessage = success;
      notifyListeners();
      return true;
    } catch (e) {
      _mutationStatus = HomeStatus.failure;
      _errorMessage = _message(e);
      notifyListeners();
      return false;
    }
  }

  String _message(Object e) => e.toString().replaceFirst('Exception: ', '');
}
