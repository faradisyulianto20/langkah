import 'package:flutter/material.dart';
import 'package:langkah/core/utils/date_helpers.dart';
import 'package:langkah/core/utils/ui_feedback.dart';
import 'package:langkah/features/planner/domain/backlog_item.dart';
import 'package:langkah/features/planner/presentation/planner_view_model.dart';
import 'package:langkah/features/planner/presentation/widgets/sheet_scaffold.dart';
import 'package:provider/provider.dart';

/// Backlog Pool: tampung ide, lalu jadwalkan ke tanggal tertentu.
class BacklogSheet extends StatefulWidget {
  const BacklogSheet({super.key});

  @override
  State<BacklogSheet> createState() => _BacklogSheetState();
}

class _BacklogSheetState extends State<BacklogSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    final vm = context.read<PlannerViewModel>();
    final ok = await vm.addBacklog(title: text);
    if (!mounted) return;
    if (ok) {
      _ctrl.clear();
    } else {
      UIFeedback.showError(context, vm.errorMessage ?? 'Gagal menambah.');
    }
  }

  Future<void> _schedule(BacklogItem item) async {
    final vm = context.read<PlannerViewModel>();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateHelpers.dateOnly(now),
      firstDate: DateHelpers.dateOnly(now),
      lastDate: DateTime(now.year + 2),
      helpText: 'Jadwalkan "${item.title}"',
    );
    if (picked == null || !mounted) return;
    final ok = await vm.scheduleBacklog(item, picked);
    if (!mounted) return;
    if (ok) {
      UIFeedback.showSuccess(context, vm.successMessage ?? 'Dijadwalkan.');
    } else {
      UIFeedback.showError(context, vm.errorMessage ?? 'Gagal menjadwalkan.');
    }
  }

  Future<void> _delete(BacklogItem item) async {
    final vm = context.read<PlannerViewModel>();
    final ok = await vm.deleteBacklog(item.id);
    if (!ok && mounted) {
      UIFeedback.showError(context, vm.errorMessage ?? 'Gagal menghapus.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlannerViewModel>();
    final theme = Theme.of(context);

    return SheetScaffold(
      title: 'Backlog Pool',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _add(),
                  decoration: const InputDecoration(
                    hintText: 'Catat ide atau tugas baru…',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: vm.isMutating ? null : _add,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (vm.backlog.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Backlog kosong. Catat ide apa saja di atas.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: vm.backlog.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final item = vm.backlog[i];
                  final category = vm.categoryById(item.categoryId);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.title),
                    subtitle: category == null ? null : Text(category.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Jadwalkan',
                          icon: const Icon(Icons.event_available_rounded),
                          onPressed: vm.isMutating
                              ? null
                              : () => _schedule(item),
                        ),
                        IconButton(
                          tooltip: 'Hapus',
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: vm.isMutating ? null : () => _delete(item),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
