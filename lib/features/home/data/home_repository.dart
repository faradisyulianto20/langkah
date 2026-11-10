import 'package:langkah/features/home/domain/category.dart';
import 'package:langkah/features/home/domain/daily_task.dart';
import 'package:langkah/features/settings/domain/profile_model.dart';
import 'package:langkah/features/settings/domain/streak_data.dart';

abstract class HomeRepository {
  Future<List<DailyTask>> getTasksForDay(DateTime day);
  Future<List<Category>> getCategories();
  Future<StreakData> getStats();

  /// Profil (nama & foto) untuk avatar di AppBar.
  Future<ProfileModel> getProfile();

  Future<DailyTask> addTask({
    required String title,
    required DateTime date,
    TaskPriority priority = TaskPriority.medium,
    String? categoryId,
  });

  Future<DailyTask> updateTask(DailyTask task);
  Future<void> deleteTask(String id);

  /// Mencentang/membatalkan tugas. Mengembalikan statistik terbaru, atau
  /// null bila sinkron streak gagal (centang sendiri tetap tersimpan).
  Future<StreakData?> setTaskCompleted(String id, bool completed);

  Future<void> addBacklogItem({required String title, String? categoryId});
}
