import 'package:flutter/material.dart';
import 'package:langkah/core/constants/app_colors.dart';
import 'package:langkah/features/home/domain/category.dart';
import 'package:langkah/features/home/domain/daily_task.dart';

Color homePriorityColor(TaskPriority p) => switch (p) {
  TaskPriority.high => AppColors.error,
  TaskPriority.medium => AppColors.warning,
  TaskPriority.low => AppColors.info,
};

/// Kartu langkah hari ini: centang satu ketukan, badge kategori, prioritas.
class HomeTaskTile extends StatelessWidget {
  final DailyTask task;
  final Category? category;

  /// null = centang dikunci.
  final VoidCallback? onToggle;
  final VoidCallback onTap;
  final VoidCallback? onFocus;
  final VoidCallback onDelete;

  const HomeTaskTile({
    super.key,
    required this.task,
    required this.category,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
    this.onFocus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = task.isCompleted;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
          child: Row(
            children: [
              Checkbox(
                value: done,
                onChanged: onToggle == null ? null : (_) => onToggle!(),
              ),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: homePriorityColor(task.priority),
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        decoration: done ? TextDecoration.lineThrough : null,
                        color: done ? context.mutedText : null,
                      ),
                    ),
                    if (category != null)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: category!.color.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          category!.name,
                          style: TextStyle(
                            color: category!.color,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (onFocus != null)
                IconButton(
                  tooltip: 'Fokus dengan Pomodoro',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.timer_outlined, size: 20),
                  onPressed: onFocus,
                ),
              IconButton(
                tooltip: 'Hapus',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
