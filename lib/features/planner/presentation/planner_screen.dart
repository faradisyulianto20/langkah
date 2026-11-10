import 'package:flutter/material.dart';
import 'package:langkah/core/network/supabase_config.dart';
import 'package:langkah/core/utils/date_helpers.dart';
import 'package:langkah/core/utils/ui_feedback.dart';
import 'package:langkah/features/planner/data/planner_repository_impl.dart';
import 'package:langkah/features/planner/domain/monthly_goal.dart';
import 'package:langkah/features/planner/domain/weekly_target.dart';
import 'package:langkah/features/planner/presentation/planner_view_model.dart';
import 'package:langkah/features/planner/presentation/widgets/backlog_sheet.dart';
import 'package:langkah/features/planner/presentation/widgets/day_board.dart';
import 'package:langkah/features/planner/presentation/widgets/goal_form_sheet.dart';
import 'package:langkah/features/planner/presentation/widgets/planner_cards.dart';
import 'package:langkah/features/planner/presentation/widgets/progress_hero.dart';
import 'package:langkah/features/planner/presentation/widgets/sheet_scaffold.dart';
import 'package:langkah/features/planner/presentation/widgets/target_form_sheet.dart';
import 'package:langkah/features/planner/presentation/widgets/task_form_sheet.dart';
import 'package:provider/provider.dart';

class PlannerScreen extends StatelessWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PlannerViewModel(repository: PlannerRepositoryImpl()),
      child: const _PlannerBody(),
    );
  }
}

class _PlannerBody extends StatefulWidget {
  const _PlannerBody();

  @override
  State<_PlannerBody> createState() => _PlannerBodyState();
}

class _PlannerBodyState extends State<_PlannerBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!SupabaseConfig.isInitialized || !mounted) return;
      context.read<PlannerViewModel>().load();
    });
  }

  // ───────────── Aksi ─────────────

  Future<void> _onFabPressed(PlannerViewModel vm) async {
    if (vm.mode == PlannerMode.monthly) {
      await showPlannerSheet(context, child: const GoalFormSheet());
      return;
    }
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.track_changes_rounded),
              title: const Text('Target Mingguan'),
              onTap: () => Navigator.pop(ctx, 'target'),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline_rounded),
              title: const Text('Tugas Harian'),
              onTap: () => Navigator.pop(ctx, 'task'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'target') {
      await showPlannerSheet(context, child: const TargetFormSheet());
    } else {
      await _addTask(vm.selectedDay);
    }
  }

  Future<void> _addTask(DateTime day) async {
    await showPlannerSheet(context, child: TaskFormSheet(initialDate: day));
  }

  Future<bool> _confirmDelete(String what) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus?'),
        content: Text('"$what" akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _onGoalTap(MonthlyGoal goal) async {
    await showPlannerSheet(context, child: GoalFormSheet(goal: goal));
  }

  Future<void> _onTargetAction(CardAction a, WeeklyTarget target) async {
    final vm = context.read<PlannerViewModel>();
    if (a == CardAction.edit) {
      await showPlannerSheet(context, child: TargetFormSheet(target: target));
    } else if (await _confirmDelete(target.title)) {
      final ok = await vm.deleteTarget(target.id);
      if (mounted) _feedback(vm, ok);
    }
  }

  void _feedback(PlannerViewModel vm, bool ok) {
    if (ok) {
      UIFeedback.showSuccess(context, vm.successMessage ?? 'Berhasil.');
    } else {
      UIFeedback.showError(context, vm.errorMessage ?? 'Terjadi kesalahan.');
    }
  }

  // ───────────── Build ─────────────

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlannerViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planner'),
        actions: [
          IconButton(
            tooltip: 'Backlog Pool',
            onPressed: () =>
                showPlannerSheet(context, child: const BacklogSheet()),
            icon: Badge(
              isLabelVisible: vm.backlog.isNotEmpty,
              label: Text('${vm.backlog.length}'),
              child: const Icon(Icons.inbox_outlined),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onFabPressed(vm),
        tooltip: vm.mode == PlannerMode.weekly
            ? 'Tambah target / tugas'
            : 'Tambah sasaran',
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<PlannerMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: PlannerMode.weekly,
                    label: Text('Mingguan'),
                    icon: Icon(Icons.view_week_outlined),
                  ),
                  ButtonSegment(
                    value: PlannerMode.monthly,
                    label: Text('Bulanan'),
                    icon: Icon(Icons.calendar_month_outlined),
                  ),
                ],
                selected: {vm.mode},
                onSelectionChanged: (s) => vm.setMode(s.first),
              ),
            ),
          ),
          _PeriodHeader(vm: vm),
          Expanded(
            child: _Content(
              vm: vm,
              onAddTask: _addTask,
              onGoal: _onGoalTap,
              onTarget: _onTargetAction,
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodHeader extends StatelessWidget {
  final PlannerViewModel vm;

  const _PeriodHeader({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Sebelumnya',
            onPressed: vm.goPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  vm.periodTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  vm.periodSubtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (!vm.isCurrentPeriod)
                  TextButton(
                    onPressed: vm.goToToday,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(
                      vm.mode == PlannerMode.weekly
                          ? 'Ke minggu ini'
                          : 'Ke bulan ini',
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Berikutnya',
            onPressed: vm.goNext,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final PlannerViewModel vm;
  final ValueChanged<DateTime> onAddTask;
  final Future<void> Function(MonthlyGoal) onGoal;
  final Future<void> Function(CardAction, WeeklyTarget) onTarget;

  const _Content({
    required this.vm,
    required this.onAddTask,
    required this.onGoal,
    required this.onTarget,
  });

  bool get _hasData => vm.mode == PlannerMode.weekly
      ? (vm.weekTargets.isNotEmpty || vm.weekTasks.isNotEmpty)
      : vm.goals.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (vm.status == PlannerStatus.failure && !_hasData) {
      return _Message(
        icon: Icons.cloud_off_rounded,
        text: vm.errorMessage ?? 'Gagal memuat data.',
        actionLabel: 'Coba lagi',
        onAction: vm.load,
      );
    }
    if ((vm.status == PlannerStatus.loading ||
            vm.status == PlannerStatus.initial) &&
        !_hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: vm.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          if (vm.isLoading) const LinearProgressIndicator(minHeight: 2),
          if (vm.status == PlannerStatus.failure)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                vm.errorMessage ?? 'Gagal memuat data.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (vm.mode == PlannerMode.weekly)
            ..._weekly(context)
          else
            ..._monthly(context),
        ],
      ),
    );
  }

  List<Widget> _monthly(BuildContext context) {
    final hero = ProgressHero(
      title: 'Progres sasaran ${DateHelpers.monthName(vm.month.month)}',
      unit: 'sasaran selesai',
      progress: vm.monthGoalProgress,
      secondaryLabel: 'Target mingguan tertaut',
      secondary: vm.monthTargetProgress,
      emptyHint: 'Tentukan sasaran bulan ini untuk mulai melacak progres.',
    );
    if (vm.goals.isEmpty) {
      return [
        hero,
        const _InlineEmpty(
          icon: Icons.flag_outlined,
          text: 'Belum ada sasaran bulan ini.\nKetuk + untuk menambah sasaran.',
        ),
      ];
    }
    return [
      hero,
      for (final g in vm.goals)
        MonthlyGoalCard(
          goal: g,
          progress: vm.targetProgressForGoal(g.id),
          onTap: () => onGoal(g),
          onToggle: () async {
            final ok = await vm.toggleGoalCompleted(g);
            if (!ok && context.mounted) {
              UIFeedback.showError(
                context,
                vm.errorMessage ?? 'Gagal memperbarui.',
              );
            }
          },
        ),
    ];
  }

  List<Widget> _weekly(BuildContext context) {
    final theme = Theme.of(context);
    return [
      ProgressHero(
        title: 'Target minggu ini',
        unit: 'target selesai',
        progress: vm.weekTargetProgress,
        secondaryLabel: 'Tugas harian minggu ini',
        secondary: vm.weekTaskProgress,
        emptyHint: 'Tentukan target mingguan agar langkahmu punya arah.',
      ),
      _SectionTitle('Target Mingguan'),
      if (vm.weekTargets.isEmpty)
        const _InlineEmpty(
          icon: Icons.track_changes_rounded,
          text: 'Belum ada target minggu ini.',
        )
      else
        for (final t in vm.weekTargets)
          WeeklyTargetCard(
            target: t,
            goalTitle: vm.goalById(t.monthlyGoalId)?.title,
            taskProgress: vm.taskProgressForTarget(t.id),
            onToggle: () async {
              final ok = await vm.toggleTargetCompleted(t);
              if (!ok && context.mounted) {
                UIFeedback.showError(
                  context,
                  vm.errorMessage ?? 'Gagal memperbarui.',
                );
              }
            },
            onAction: (a) => onTarget(a, t),
          ),
      const SizedBox(height: 12),
      _SectionTitle('Tugas 7 Hari'),
      if (vm.unlinkedTaskCount > 0 && vm.weekTargets.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            '${vm.unlinkedTaskCount} tugas belum terhubung ke target mingguan.',
            style: theme.textTheme.bodySmall,
          ),
        ),
      DayBoard(onAddTask: onAddTask),
    ];
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InlineEmpty({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(icon, size: 36, color: Theme.of(context).hintColor),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  final String actionLabel;
  final VoidCallback onAction;

  const _Message({
    required this.icon,
    required this.text,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).hintColor),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
