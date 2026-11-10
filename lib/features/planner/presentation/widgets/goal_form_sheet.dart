import 'package:flutter/material.dart';
import 'package:langkah/core/utils/ui_feedback.dart';
import 'package:langkah/core/widgets/custom_button.dart';
import 'package:langkah/core/widgets/custom_text_field.dart';
import 'package:langkah/features/planner/domain/goal_status.dart';
import 'package:langkah/features/planner/domain/monthly_goal.dart';
import 'package:langkah/features/planner/presentation/planner_view_model.dart';
import 'package:langkah/features/planner/presentation/widgets/sheet_scaffold.dart';
import 'package:provider/provider.dart';

/// Form tambah/edit sasaran bulanan.
class GoalFormSheet extends StatefulWidget {
  final MonthlyGoal? goal;

  const GoalFormSheet({super.key, this.goal});

  @override
  State<GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends State<GoalFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final GoalStatus _status;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.goal?.title ?? '');
    _descCtrl = TextEditingController(text: widget.goal?.description ?? '');
    _status = widget.goal?.status ?? GoalStatus.pending;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = context.read<PlannerViewModel>();
    final goal = widget.goal;
    final ok = goal == null
        ? await vm.addGoal(
            title: _titleCtrl.text,
            description: _descCtrl.text,
            status: _status,
          )
        : await vm.updateGoal(
            goal,
            title: _titleCtrl.text,
            description: _descCtrl.text,
            status: _status,
          );
    if (!mounted) return;
    if (ok) {
      UIFeedback.showSuccess(context, vm.successMessage ?? 'Tersimpan.');
      Navigator.of(context).pop();
    } else {
      UIFeedback.showError(context, vm.errorMessage ?? 'Gagal menyimpan.');
    }
  }

  Future<void> _delete() async {
    final goal = widget.goal;
    if (goal == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus sasaran?'),
        content: Text('"${goal.title}" akan dihapus permanen.'),
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
    if (confirm != true || !mounted) return;
    final vm = context.read<PlannerViewModel>();
    final ok = await vm.deleteGoal(goal.id);
    if (!mounted) return;
    if (ok) {
      UIFeedback.showSuccess(context, vm.successMessage ?? 'Dihapus.');
      Navigator.of(context).pop();
    } else {
      UIFeedback.showError(context, vm.errorMessage ?? 'Gagal menghapus.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMutating = context.select<PlannerViewModel, bool>(
      (v) => v.isMutating,
    );
    return SheetScaffold(
      title: widget.goal == null ? 'Sasaran Bulanan Baru' : 'Edit Sasaran',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              controller: _titleCtrl,
              label: 'Sasaran',
              hint: 'Contoh: Selesaikan modul Flutter',
              prefixIcon: Icons.flag_outlined,
              validator: requiredValidator,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _descCtrl,
              label: 'Deskripsi (opsional)',
              prefixIcon: Icons.notes_rounded,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Simpan',
              onPressed: _submit,
              isLoading: isMutating,
            ),
            if (widget.goal != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: isMutating ? null : _delete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Hapus sasaran'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Pemilih status (Belum mulai / Berjalan / Selesai).
class StatusSelector extends StatelessWidget {
  final GoalStatus value;
  final ValueChanged<GoalStatus> onChanged;

  const StatusSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<GoalStatus>(
        showSelectedIcon: false,
        segments: [
          for (final s in GoalStatus.values)
            ButtonSegment(value: s, label: Text(s.label)),
        ],
        selected: {value},
        onSelectionChanged: (set) => onChanged(set.first),
      ),
    );
  }
}
