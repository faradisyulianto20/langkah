import 'package:flutter/material.dart';
import 'package:langkah/core/constants/app_colors.dart';
import 'package:langkah/core/network/supabase_config.dart';
import 'package:langkah/core/utils/ui_feedback.dart';
import 'package:langkah/core/widgets/user_avatar.dart';
import 'package:langkah/features/home/data/home_repository_impl.dart';
import 'package:langkah/features/home/data/pomodoro_notifier.dart';
import 'package:langkah/features/home/domain/daily_task.dart';
import 'package:langkah/features/home/presentation/home_view_model.dart';
import 'package:langkah/features/home/presentation/pomodoro_controller.dart';
import 'package:langkah/features/home/presentation/pomodoro_screen.dart';
import 'package:langkah/features/home/presentation/widgets/feature_card.dart';
import 'package:langkah/features/home/presentation/widgets/home_task_tile.dart';
import 'package:langkah/features/home/presentation/widgets/quick_add_sheet.dart';
import 'package:langkah/features/home/presentation/widgets/today_header.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  /// Dipicu setiap kali tab Home dibuka kembali agar data tersinkron.
  final Listenable? refreshSignal;

  const HomeScreen({super.key, this.refreshSignal});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => HomeViewModel(repository: HomeRepositoryImpl()),
        ),
        // Hidup selama Home hidup: timer tetap jalan saat halaman Pomodoro
        // ditutup atau pindah tab.
        ChangeNotifierProvider(
          create: (_) => PomodoroController(notifier: LocalPomodoroNotifier()),
        ),
      ],
      child: _HomeBody(refreshSignal: refreshSignal),
    );
  }
}

class _HomeBody extends StatefulWidget {
  final Listenable? refreshSignal;

  const _HomeBody({this.refreshSignal});

  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> {
  @override
  void initState() {
    super.initState();
    widget.refreshSignal?.addListener(_load);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    widget.refreshSignal?.removeListener(_load);
    super.dispose();
  }

  void _load() {
    if (!SupabaseConfig.isInitialized || !mounted) return;
    context.read<HomeViewModel>().load();
  }

  String get _fallbackName {
    final user = SupabaseConfig.isInitialized
        ? SupabaseConfig.client.auth.currentUser
        : null;
    final meta = user?.userMetadata;
    return (meta?['username'] as String?) ??
        user?.email?.split('@').first ??
        'Teman Langkah';
  }

  void _openPomodoro() {
    final home = context.read<HomeViewModel>();
    final pomodoro = context.read<PomodoroController>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: home),
            ChangeNotifierProvider.value(value: pomodoro),
          ],
          child: const PomodoroScreen(),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(HomeViewModel vm, DailyTask task) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus langkah?'),
        content: Text('"${task.title}" akan dihapus permanen.'),
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
    if (ok != true || !mounted) return;
    final done = await vm.deleteTask(task);
    if (!mounted) return;
    if (!done) {
      UIFeedback.showError(context, vm.errorMessage ?? 'Gagal menghapus.');
    }
  }

  Future<void> _toggle(HomeViewModel vm, DailyTask task) async {
    final ok = await vm.toggleTask(task);
    if (!ok && mounted) {
      UIFeedback.showError(context, vm.errorMessage ?? 'Gagal memperbarui.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final name = vm.profile?.displayName ?? _fallbackName;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.tealPrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.directions_walk_rounded,
                color: AppColors.tealPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Langkah',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                UserAvatar(
                  name: name,
                  imageUrl: vm.profile?.avatarUrl,
                  radius: 17,
                ),
              ],
            ),
          ),
        ],
      ),
      // Tombol biasa (bukan FAB) yang menempel tepat di atas navbar.
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: () => showQuickAddSheet(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Tambah Langkah',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: vm.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (vm.isLoading) const LinearProgressIndicator(minHeight: 2),
            if (vm.status == HomeStatus.failure)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        vm.errorMessage ?? 'Gagal memuat data.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: vm.load,
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            TodayHeader(
              today: vm.today,
              streak: vm.streak,
              progress: vm.progress,
            ),
            const SizedBox(height: 20),
            ..._tasksSection(context, vm),
            const SizedBox(height: 24),
            _MoreMenu(onPomodoro: _openPomodoro),
          ],
        ),
      ),
    );
  }

  List<Widget> _tasksSection(BuildContext context, HomeViewModel vm) {
    final theme = Theme.of(context);
    final initialLoad =
        vm.status == HomeStatus.initial ||
        (vm.status == HomeStatus.loading && vm.tasks.isEmpty);

    if (initialLoad) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    final children = <Widget>[
      Text(
        'Langkah Hari Ini',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
    ];

    if (vm.categories.isNotEmpty && vm.tasks.isNotEmpty) {
      children.add(
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: const Text('Semua'),
                  selected: vm.filterCategoryId == null,
                  onSelected: (_) => vm.setFilter(null),
                ),
              ),
              for (final c in vm.categories)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: CircleAvatar(backgroundColor: c.color, radius: 5),
                    label: Text(c.name),
                    selected: vm.filterCategoryId == c.id,
                    onSelected: (sel) => vm.setFilter(sel ? c.id : null),
                  ),
                ),
            ],
          ),
        ),
      );
      children.add(const SizedBox(height: 8));
    }

    if (vm.tasks.isEmpty) {
      children.add(_EmptyToday(onAdd: () => showQuickAddSheet(context)));
      return children;
    }

    final pending = vm.pendingTasks;
    final done = vm.doneTasks;
    if (pending.isEmpty && done.isEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Text(
              'Tidak ada langkah di kategori ini.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
      );
      return children;
    }

    Widget tile(DailyTask t, {required bool focusable}) => HomeTaskTile(
      task: t,
      category: vm.categoryById(t.categoryId),
      onToggle: vm.canToggle(t) ? () => _toggle(vm, t) : null,
      onTap: () => showQuickAddSheet(context, task: t),
      onDelete: () => _confirmDelete(vm, t),
      onFocus: focusable
          ? () {
              context.read<PomodoroController>().setTask(t.title);
              _openPomodoro();
            }
          : null,
    );

    children.addAll([for (final t in pending) tile(t, focusable: true)]);

    if (done.isNotEmpty) {
      children.addAll([
        const SizedBox(height: 8),
        Text(
          'Selesai (${done.length})',
          style: theme.textTheme.titleSmall?.copyWith(color: context.mutedText),
        ),
        const SizedBox(height: 8),
        for (final t in done) tile(t, focusable: false),
      ]);
    }
    return children;
  }
}

/// Kumpulan fitur tambahan. Fitur baru (mis. Gym Tracker) cukup menambah
/// satu [FeatureCard] di sini.
class _MoreMenu extends StatelessWidget {
  final VoidCallback onPomodoro;

  const _MoreMenu({required this.onPomodoro});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pomodoro = context.watch<PomodoroController>();

    final cards = <Widget>[
      FeatureCard(
        icon: Icons.timer_outlined,
        label: 'Pomodoro',
        color: AppColors.tealPrimary,
        // Titik hijau menandakan timer sedang berjalan.
        active: pomodoro.isRunning,
        onTap: onPomodoro,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Menu Tambahan',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            const columns = 4;
            const gap = 12.0;
            final width =
                (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final c in cards) SizedBox(width: width, child: c),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _EmptyToday extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyToday({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      child: Column(
        children: [
          const Icon(
            Icons.wb_twilight_rounded,
            size: 40,
            color: AppColors.tealPrimary,
          ),
          const SizedBox(height: 12),
          Text(
            'Hari ini masih kosong',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Satu langkah kecil yang jelas lebih berharga daripada rencana '
            'besar yang tak dimulai. Tulis yang paling penting dulu.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tambah langkah pertama'),
          ),
        ],
      ),
    );
  }
}
