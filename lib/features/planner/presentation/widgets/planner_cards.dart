import 'package:flutter/material.dart';
import 'package:langkah/core/constants/app_colors.dart';
import 'package:langkah/features/planner/domain/goal_status.dart';
import 'package:langkah/features/planner/domain/monthly_goal.dart';
import 'package:langkah/features/planner/domain/weekly_target.dart';

Color statusColor(GoalStatus s) => switch (s) {
  GoalStatus.pending => AppColors.textSecondary,
  GoalStatus.inProgress => AppColors.info,
  GoalStatus.completed => AppColors.success,
};

class StatusChip extends StatelessWidget {
  final GoalStatus status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

enum CardAction { edit, delete }

class _CardMenu extends StatelessWidget {
  final ValueChanged<CardAction> onSelected;

  const _CardMenu({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<CardAction>(
      icon: const Icon(Icons.more_vert_rounded, size: 20),
      onSelected: onSelected,
      itemBuilder: (_) => const [
        PopupMenuItem(value: CardAction.edit, child: Text('Edit')),
        PopupMenuItem(value: CardAction.delete, child: Text('Hapus')),
      ],
    );
  }
}

/// Kartu sasaran bulanan: centang langsung untuk menyelesaikan,
/// ketuk kartu untuk mengedit/menghapus.
class MonthlyGoalCard extends StatelessWidget {
  final MonthlyGoal goal;
  final ({int done, int total}) progress;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  const MonthlyGoalCard({
    super.key,
    required this.goal,
    required this.progress,
    required this.onToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = goal.status == GoalStatus.completed;
    final ratio = progress.total == 0 ? 0.0 : progress.done / progress.total;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                tooltip: done ? 'Tandai belum selesai' : 'Tandai selesai',
                onPressed: onToggle,
                icon: Icon(
                  done
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: done ? AppColors.success : AppColors.textSecondary,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if ((goal.description ?? '').isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          goal.description!,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                      if (progress.total > 0) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: ratio,
                                  minHeight: 5,
                                  color: AppColors.tealPrimary,
                                  backgroundColor: AppColors.divider,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${progress.done}/${progress.total} target',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ],
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

/// Kartu target mingguan: centang selesai + kontribusi tugas harian.
class WeeklyTargetCard extends StatelessWidget {
  final WeeklyTarget target;
  final String? goalTitle;
  final ({int done, int total}) taskProgress;
  final VoidCallback onToggle;
  final ValueChanged<CardAction> onAction;

  const WeeklyTargetCard({
    super.key,
    required this.target,
    required this.goalTitle,
    required this.taskProgress,
    required this.onToggle,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = target.status == GoalStatus.completed;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              onPressed: onToggle,
              icon: Icon(
                done
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: done ? AppColors.success : AppColors.textSecondary,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      target.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StatusChip(status: target.status),
                        if (goalTitle != null)
                          Text(
                            '↳ $goalTitle',
                            style: theme.textTheme.bodySmall,
                          ),
                        Text(
                          taskProgress.total == 0
                              ? 'Belum ada tugas harian'
                              : '${taskProgress.done}/${taskProgress.total} tugas selesai',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            _CardMenu(onSelected: onAction),
          ],
        ),
      ),
    );
  }
}
