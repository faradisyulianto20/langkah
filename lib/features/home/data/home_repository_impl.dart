import 'package:flutter/foundation.dart' show debugPrint;
import 'package:langkah/core/network/supabase_config.dart';
import 'package:langkah/core/utils/date_helpers.dart';
import 'package:langkah/features/home/data/home_repository.dart';
import 'package:langkah/features/home/data/stats_repository.dart';
import 'package:langkah/features/home/data/stats_repository_impl.dart';
import 'package:langkah/features/home/domain/category.dart';
import 'package:langkah/features/home/domain/daily_task.dart';
import 'package:langkah/features/settings/domain/profile_model.dart';
import 'package:langkah/features/settings/domain/streak_data.dart';

class HomeRepositoryImpl implements HomeRepository {
  final StatsRepository _stats;

  HomeRepositoryImpl({StatsRepository? stats})
    : _stats = stats ?? StatsRepositoryImpl();

  String get _uid {
    final id = SupabaseConfig.client.auth.currentUser?.id;
    if (id == null) throw Exception('Sesi berakhir. Silakan login ulang.');
    return id;
  }

  @override
  Future<List<DailyTask>> getTasksForDay(DateTime day) => _guard(() async {
    final rows = await SupabaseConfig.client
        .from('daily_tasks')
        .select()
        .eq('user_id', _uid)
        .eq('scheduled_date', DateHelpers.toSqlDate(day))
        .order('created_at');
    return rows.map(DailyTask.fromMap).toList();
  });

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
  Future<StreakData> getStats() => _stats.getStats();

  @override
  Future<ProfileModel> getProfile() => _guard(() async {
    final uid = _uid;
    final row = await SupabaseConfig.client
        .from('profiles')
        .select()
        .eq('id', uid)
        .maybeSingle();
    return row == null ? ProfileModel(id: uid) : ProfileModel.fromMap(row);
  });

  @override
  Future<DailyTask> addTask({
    required String title,
    required DateTime date,
    TaskPriority priority = TaskPriority.medium,
    String? categoryId,
  }) => _guard(() async {
    final row = await SupabaseConfig.client
        .from('daily_tasks')
        .insert({
          'user_id': _uid,
          'title': title,
          'scheduled_date': DateHelpers.toSqlDate(date),
          'priority': priority.value,
          'category_id': categoryId,
        })
        .select()
        .single();
    return DailyTask.fromMap(row);
  });

  @override
  Future<DailyTask> updateTask(DailyTask task) => _guard(() async {
    final row = await SupabaseConfig.client
        .from('daily_tasks')
        .update({
          'title': task.title,
          'priority': task.priority.value,
          'category_id': task.categoryId,
        })
        .eq('id', task.id)
        .select()
        .single();
    return DailyTask.fromMap(row);
  });

  @override
  Future<void> deleteTask(String id) => _guard(() async {
    await SupabaseConfig.client.from('daily_tasks').delete().eq('id', id);
  });

  @override
  Future<StreakData?> setTaskCompleted(String id, bool completed) async {
    await _guard(() async {
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
    try {
      return await _stats.recordTaskToggle(completed: completed);
    } catch (e) {
      debugPrint('[HomeRepository] sinkron streak gagal: $e');
      return null;
    }
  }

  @override
  Future<void> addBacklogItem({required String title, String? categoryId}) =>
      _guard(() async {
        await SupabaseConfig.client.from('backlog_items').insert({
          'user_id': _uid,
          'title': title,
          'category_id': categoryId,
        });
      });

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      if (e is Exception && e.toString().contains('Sesi berakhir')) rethrow;
      final message = e.toString();
      debugPrint('[HomeRepository] ${e.runtimeType}: $message');
      if (message.contains('row-level security') ||
          message.contains('permission denied')) {
        throw Exception('Akses ditolak. Silakan login ulang.');
      }
      if (message.contains('SocketException') ||
          message.contains('ClientException') ||
          message.contains('connection') ||
          message.contains('network')) {
        throw Exception(
          'Gagal terhubung ke server. Periksa koneksi internet Anda.',
        );
      }
      throw Exception('Terjadi kesalahan. Silakan coba lagi.');
    }
  }
}
