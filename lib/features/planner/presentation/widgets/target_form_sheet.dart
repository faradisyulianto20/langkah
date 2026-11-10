import 'package:flutter/material.dart';
import 'package:langkah/core/utils/ui_feedback.dart';
import 'package:langkah/core/widgets/custom_button.dart';
import 'package:langkah/core/widgets/custom_text_field.dart';
import 'package:langkah/features/planner/domain/goal_status.dart';
import 'package:langkah/features/planner/domain/weekly_target.dart';
import 'package:langkah/features/planner/presentation/planner_view_model.dart';
import 'package:langkah/features/planner/presentation/widgets/goal_form_sheet.dart';
import 'package:langkah/features/planner/presentation/widgets/sheet_scaffold.dart';
import 'package:provider/provider.dart';

/// Form tambah/edit target mingguan.
class TargetFormSheet extends StatefulWidget {
  final WeeklyTarget? target;

  const TargetFormSheet({super.key, this.target});

  @override
  State<TargetFormSheet> createState() => _TargetFormSheetState();
}

class _TargetFormSheetState extends State<TargetFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  String? _goalId;
  late GoalStatus _status;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.target?.title ?? '');
    _goalId = widget.target?.monthlyGoalId;
    _status = widget.target?.status ?? GoalStatus.pending;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = context.read<PlannerViewModel>();
    final target = widget.target;
    final ok = target == null
        ? await vm.addTarget(
            title: _titleCtrl.text,
            monthlyGoalId: _goalId,
            status: _status,
          )
        : await vm.updateTarget(
            target,
            title: _titleCtrl.text,
            monthlyGoalId: _goalId,
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

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlannerViewModel>();
    // Pastikan nilai dropdown selalu ada di daftar item.
    final goalValue = vm.goals.any((g) => g.id == _goalId) ? _goalId : null;

    return SheetScaffold(
      title: widget.target == null ? 'Target Mingguan Baru' : 'Edit Target',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              controller: _titleCtrl,
              label: 'Target',
              hint: 'Contoh: Selesaikan 3 bab',
              prefixIcon: Icons.track_changes_rounded,
              validator: requiredValidator,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              initialValue: goalValue,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Sasaran bulanan (opsional)',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Tanpa sasaran bulanan'),
                ),
                for (final g in vm.goals)
                  DropdownMenuItem<String?>(
                    value: g.id,
                    child: Text(g.title, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => setState(() => _goalId = v),
            ),
            const SizedBox(height: 16),
            StatusSelector(
              value: _status,
              allowCompleted: widget.target == null
                  ? vm.focusWeekIsCurrent
                  : vm.canToggleTarget(widget.target!),
              onChanged: (s) => setState(() => _status = s),
            ),
            if (!(widget.target == null
                ? vm.focusWeekIsCurrent
                : vm.canToggleTarget(widget.target!)))
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Status "Selesai" hanya bisa dipilih pada minggunya.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Simpan',
              onPressed: _submit,
              isLoading: vm.isMutating,
            ),
          ],
        ),
      ),
    );
  }
}
