import 'package:flutter/material.dart';
import 'package:langkah/core/constants/app_colors.dart';
import 'package:langkah/core/utils/date_helpers.dart';
import 'package:langkah/features/home/domain/daily_task.dart';
import 'package:langkah/features/planner/presentation/planner_view_model.dart';
import 'package:langkah/features/planner/presentation/widgets/sheet_scaffold.dart';
import 'package:langkah/features/planner/presentation/widgets/task_form_sheet.dart';
import 'package:provider/provider.dart';

Color priorityColor(TaskPriority p) => switch (p) {
  TaskPriority.high => AppColors.error,
  TaskPriority.medium => AppColors.warning,
  TaskPriority.low => AppColors.info,
};

/// Papan 7 hari dalam 2 baris:
/// 1. Header 7 kartu hari (flex row) untuk memilih tanggal.
/// 2. Daftar tugas hari yang dipilih, lengkap dengan progres `x/y`.
class DayBoard extends StatelessWidget {
  final ValueChanged<DateTime> onAddTask;

  const DayBoard({super.key, required this.onAddTask});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlannerViewModel>();
    final selected = vm.selectedDay;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final day in vm.weekDays)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _DayChip(
                    day: day,
                    selected: DateHelpers.isSameDay(day, selected),
                    progress: vm.progressForDay(day),
                    onTap: () => vm.selectDay(day),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _DayPanel(
          day: selected,
          tasks: vm.tasksForDay(selected),
          progress: vm.progressForDay(selected),
          onAdd: () => onAddTask(selected),
        ),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  final DateTime day;
  final bool selected;
  final ({int done, int total}) progress;
  final VoidCallback onTap;

  const _DayChip({
    required this.day,
    required this.selected,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = DateHelpers.isSameDay(day, DateTime.now());
    final fg = selected ? Colors.white : theme.colorScheme.onSurface;
    final ratio = progress.total == 0 ? 0.0 : progress.done / progress.total;

    return Material(
      color: selected ? AppColors.tealPrimary : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isToday || selected
              ? AppColors.tealPrimary
              : context.borderColor,
          width: isToday ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  DateHelpers.dayName(day),
                  style: TextStyle(
                    color: fg,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${day.day}',
                style: TextStyle(
                  color: fg,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 3,
                    color: selected
                        ? Colors.white
                        : AppColors.progressColor(
                            progress.total == 0 ? null : ratio,
                          ),
                    backgroundColor: selected
                        ? Colors.white30
                        : context.trackColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayPanel extends StatelessWidget {
  final DateTime day;
  final List<DailyTask> tasks;
  final ({int done, int total}) progress;
  final VoidCallback onAdd;

  const _DayPanel({
    required this.day,
    required this.tasks,
    required this.progress,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = DateHelpers.isSameDay(day, DateTime.now());
    final ratio = progress.total == 0 ? 0.0 : progress.done / progress.total;

    if (tasks.isEmpty) return _EmptyDay(day: day, onAdd: onAdd);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isToday)
              Padding(
                padding: const EdgeInsets.only(right: 12, bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 14,
                      color: context.mutedText,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        day.isBefore(DateHelpers.dateOnly(DateTime.now()))
                            ? 'Hari ini sudah lewat. Centang terkunci, rencana tetap bisa diedit.'
                            : 'Belum waktunya. Centang terbuka di hari-H, rencana bisa diedit.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(right: 12, bottom: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 6,
                  color: AppColors.progressColor(ratio),
                  backgroundColor: context.trackColor,
                ),
              ),
            ),
            for (final t in tasks) _TaskTile(task: t),
            // Hari/tanggal sudah ada di grid 7 hari, jadi aksi tambah
            // ditaruh di bawah daftar.
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Tambah tugas'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hari tanpa tugas: tanpa card & progress bar, hanya ajakan + tombol.
class _EmptyDay extends StatelessWidget {
  final DateTime day;
  final VoidCallback onAdd;

  const _EmptyDay({required this.day, required this.onAdd});

  static const _upcoming = [
    'Hari yang kosong adalah kanvas. Satu tugas kecil sudah cukup untuk memulai.',
    'Rencana singkat hari ini membuat esok terasa lebih ringan.',
    'Tidak perlu banyak: pilih 1–3 hal yang paling berarti.',
    'Langkah kecil yang terjadwal lebih mungkin benar-benar dikerjakan.',
    'Tulis satu hal yang ingin kamu tuntaskan, lalu biarkan sisanya mengalir.',
    'Kemajuan besar selalu dimulai dari daftar yang sederhana.',
    'Beri dirimu tujuan kecil, dan rasakan puasnya mencentang.',
  ];

  static const _past = [
    'Hari ini sudah berlalu. Tidak apa-apa, fokus ke langkah berikutnya.',
    'Yang lalu biarlah lalu. Mulai rencanakan hari yang masih bisa kamu isi.',
  ];

  String _message(DateTime today) {
    final isPast = DateHelpers.dateOnly(day).isBefore(today);
    final list = isPast ? _past : _upcoming;
    return list[day.weekday % list.length];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateHelpers.dateOnly(DateTime.now());
    final isToday = DateHelpers.isSameDay(day, today);
    final isPast = day.isBefore(today);
    final dayName = DateHelpers.dayName(day);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      child: Column(
        children: [
          Icon(
            isPast ? Icons.history_rounded : Icons.wb_twilight_rounded,
            size: 40,
            color: AppColors.tealPrimary,
          ),
          const SizedBox(height: 12),
          Text(
            isToday ? 'Hari ini masih kosong' : '$dayName belum ada rencana',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            _message(today),
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: Text(
              isToday ? 'Rencanakan hari ini' : 'Rencanakan $dayName',
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final DailyTask task;

  const _TaskTile({required this.task});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<PlannerViewModel>();
    final theme = Theme.of(context);
    final category = vm.categoryById(task.categoryId);

    return Row(
      children: [
        Checkbox(
          value: task.isCompleted,
          // Terkunci bila bukan hari-H (tidak bisa dicentang/di-uncheck).
          onChanged: vm.canToggleTask(task)
              ? (_) async {
                  final ok = await vm.toggleTask(task);
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(vm.errorMessage ?? 'Gagal memperbarui.'),
                      ),
                    );
                  }
                }
              : null,
        ),
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: priorityColor(task.priority),
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: InkWell(
            onTap: () =>
                showPlannerSheet(context, child: TaskFormSheet(task: task)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: task.isCompleted ? context.mutedText : null,
                    ),
                  ),
                  if (category != null)
                    Text(
                      category.name,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: category.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Hapus',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.close_rounded, size: 18),
          onPressed: () => vm.deleteTask(task.id).then((ok) {
            if (!ok && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(vm.errorMessage ?? 'Gagal menghapus.')),
              );
            }
          }),
        ),
      ],
    );
  }
}
