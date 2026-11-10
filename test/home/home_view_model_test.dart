import 'package:flutter_test/flutter_test.dart';
import 'package:langkah/features/home/data/home_repository.dart';
import 'package:langkah/features/home/domain/category.dart';
import 'package:langkah/features/home/domain/daily_task.dart';
import 'package:langkah/features/home/domain/streak_calculator.dart';
import 'package:langkah/features/home/presentation/home_view_model.dart';
import 'package:langkah/features/settings/domain/profile_model.dart';
import 'package:langkah/features/settings/domain/streak_data.dart';

class FakeHomeRepo implements HomeRepository {
  FakeHomeRepo(this.now);

  final DateTime now;
  bool fail = false;
  bool streakSyncFails = false;
  int _n = 0;
  final tasks = <DailyTask>[];
  final backlog = <String>[];
  StreakData stats = StreakData.empty('u');
  final categories = const [
    Category(id: 'c1', userId: 'u', name: 'Coding'),
    Category(id: 'c2', userId: 'u', name: 'Fitness', colorHex: '#FB8C00'),
  ];

  void _check() {
    if (fail) throw Exception('Terjadi kesalahan. Silakan coba lagi.');
  }

  @override
  Future<List<DailyTask>> getTasksForDay(DateTime day) async {
    _check();
    return tasks
        .where(
          (t) =>
              t.scheduledDate.year == day.year &&
              t.scheduledDate.month == day.month &&
              t.scheduledDate.day == day.day,
        )
        .toList();
  }

  @override
  Future<List<Category>> getCategories() async => categories;

  @override
  Future<StreakData> getStats() async => stats;

  bool profileFails = false;
  ProfileModel profile = const ProfileModel(
    id: 'u',
    fullName: 'Faradis Yulianto',
    avatarUrl: 'https://example.com/a.jpg',
  );

  @override
  Future<ProfileModel> getProfile() async {
    if (profileFails) throw Exception('profil gagal');
    return profile;
  }

  @override
  Future<DailyTask> addTask({
    required String title,
    required DateTime date,
    TaskPriority priority = TaskPriority.medium,
    String? categoryId,
  }) async {
    _check();
    final t = DailyTask(
      id: 't${_n++}',
      userId: 'u',
      title: title,
      scheduledDate: date,
      priority: priority,
      categoryId: categoryId,
    );
    tasks.add(t);
    return t;
  }

  @override
  Future<DailyTask> updateTask(DailyTask task) async {
    _check();
    return task;
  }

  @override
  Future<void> deleteTask(String id) async {
    _check();
    tasks.removeWhere((t) => t.id == id);
  }

  @override
  Future<StreakData?> setTaskCompleted(String id, bool completed) async {
    _check();
    if (streakSyncFails) return null;
    stats = completed
        ? StreakCalculator.onCompleted(stats, now)
        : StreakCalculator.onUncompleted(stats, now, completedTodayAfter: 0);
    return stats;
  }

  @override
  Future<void> addBacklogItem({
    required String title,
    String? categoryId,
  }) async {
    _check();
    backlog.add(title);
  }
}

void main() {
  final now = DateTime(2026, 11, 10, 10);
  late FakeHomeRepo repo;
  late HomeViewModel vm;

  setUp(() {
    repo = FakeHomeRepo(now);
    vm = HomeViewModel(repository: repo, clock: () => now);
  });

  test('load sukses mengisi tugas hari ini, kategori & streak', () async {
    await repo.addTask(title: 'a', date: DateTime(2026, 11, 10));
    await repo.addTask(title: 'besok', date: DateTime(2026, 11, 11));
    await vm.load();
    expect(vm.status, HomeStatus.success);
    expect(vm.tasks.map((t) => t.title), ['a']); // hanya hari ini
    expect(vm.categories.length, 2);
    expect(vm.progress, (done: 0, total: 1));
  });

  test('load mengisi profil untuk avatar di AppBar', () async {
    await vm.load();
    expect(vm.profile?.displayName, 'Faradis Yulianto');
    expect(vm.profile?.avatarUrl, 'https://example.com/a.jpg');
  });

  test('gagal memuat profil tidak menggagalkan Home', () async {
    repo.profileFails = true;
    await repo.addTask(title: 'a', date: DateTime(2026, 11, 10));
    await vm.load();
    expect(vm.status, HomeStatus.success);
    expect(vm.profile, isNull);
    expect(vm.tasks.length, 1);
  });

  test('load gagal menyimpan pesan error', () async {
    repo.fail = true;
    await vm.load();
    expect(vm.status, HomeStatus.failure);
    expect(vm.errorMessage, 'Terjadi kesalahan. Silakan coba lagi.');
  });

  test('centang satu tugas menaikkan streak ke 1 & progres', () async {
    await vm.load();
    await vm.quickAdd(title: 'a', target: QuickAddTarget.today);
    await vm.quickAdd(title: 'b', target: QuickAddTarget.today);
    expect(vm.streak, 0);

    expect(await vm.toggleTask(vm.tasks.first), isTrue);
    expect(vm.progress, (done: 1, total: 2));
    expect(vm.streak, 1); // cukup satu tugas

    await vm.toggleTask(vm.tasks.last); // tugas kedua: streak tetap 1
    expect(vm.streak, 1);
  });

  test('uncheck satu-satunya tugas hari ini membatalkan streak', () async {
    await vm.load();
    await vm.quickAdd(title: 'a', target: QuickAddTarget.today);
    await vm.toggleTask(vm.tasks.single);
    expect(vm.streak, 1);
    await vm.toggleTask(vm.tasks.single);
    expect(vm.streak, 0);
  });

  test('toggle rollback bila gagal', () async {
    await vm.load();
    await vm.quickAdd(title: 'a', target: QuickAddTarget.today);
    repo.fail = true;
    expect(await vm.toggleTask(vm.tasks.single), isFalse);
    expect(vm.tasks.single.isCompleted, isFalse);
    expect(vm.errorMessage, isNotNull);
  });

  test('sinkron streak gagal: centang tetap tersimpan', () async {
    await vm.load();
    await vm.quickAdd(title: 'a', target: QuickAddTarget.today);
    repo.streakSyncFails = true;
    expect(await vm.toggleTask(vm.tasks.single), isTrue);
    expect(vm.tasks.single.isCompleted, isTrue);
  });

  test('tugas bukan milik hari ini tidak bisa dicentang', () async {
    final yesterday = DailyTask(
      id: 'y',
      userId: 'u',
      title: 'kemarin',
      scheduledDate: DateTime(2026, 11, 9),
    );
    final tomorrow = DailyTask(
      id: 'b',
      userId: 'u',
      title: 'besok',
      scheduledDate: DateTime(2026, 11, 11),
    );
    expect(vm.canToggle(yesterday), isFalse);
    expect(vm.canToggle(tomorrow), isFalse);
    expect(await vm.toggleTask(yesterday), isFalse);
    expect(vm.errorMessage, isNotNull);
  });

  test('quick add ke backlog tidak masuk daftar hari ini', () async {
    await vm.load();
    expect(
      await vm.quickAdd(title: 'ide', target: QuickAddTarget.backlog),
      isTrue,
    );
    expect(repo.backlog, ['ide']);
    expect(vm.tasks, isEmpty);
  });

  test('filter kategori tidak mengubah progres total', () async {
    await vm.load();
    await vm.quickAdd(
      title: 'a',
      target: QuickAddTarget.today,
      categoryId: 'c1',
    );
    await vm.quickAdd(
      title: 'b',
      target: QuickAddTarget.today,
      categoryId: 'c2',
    );
    vm.setFilter('c1');
    expect(vm.pendingTasks.map((t) => t.title), ['a']);
    expect(vm.progress.total, 2);
    vm.setFilter(null);
    expect(vm.pendingTasks.length, 2);
  });

  test('edit & hapus tugas', () async {
    await vm.load();
    await vm.quickAdd(title: 'a', target: QuickAddTarget.today);
    final t = vm.tasks.single;
    await vm.updateTask(
      t,
      title: 'diedit',
      priority: TaskPriority.high,
      categoryId: 'c1',
    );
    expect(vm.tasks.single.title, 'diedit');
    expect(vm.tasks.single.priority, TaskPriority.high);
    await vm.deleteTask(vm.tasks.single);
    expect(vm.tasks, isEmpty);
  });

  test('isStale true bila hari sudah berganti sejak load', () async {
    var clock = now;
    final v = HomeViewModel(repository: repo, clock: () => clock);
    await v.load();
    expect(v.isStale, isFalse);
    clock = clock.add(const Duration(days: 1));
    expect(v.isStale, isTrue);
  });
}
