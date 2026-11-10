import 'package:flutter/material.dart';
import 'package:langkah/core/utils/date_helpers.dart';
import 'package:langkah/core/utils/ui_feedback.dart';
import 'package:langkah/core/widgets/custom_button.dart';
import 'package:langkah/core/widgets/custom_text_field.dart';
import 'package:langkah/features/home/domain/daily_task.dart';
import 'package:langkah/features/planner/presentation/planner_view_model.dart';
import 'package:langkah/features/planner/presentation/widgets/sheet_scaffold.dart';
import 'package:provider/provider.dart';

/// Form tambah tugas harian kecil pada salah satu hari di minggu aktif.
class TaskFormSheet extends StatefulWidget {
  final DateTime initialDate;

  const TaskFormSheet({super.key, required this.initialDate});

  @override
  State<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<TaskFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  late DateTime _date;
  TaskPriority _priority = TaskPriority.medium;
  String? _categoryId;
  String? _targetId;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = context.read<PlannerViewModel>();
    final ok = await vm.addTask(
      title: _titleCtrl.text,
      date: _date,
      priority: _priority,
      categoryId: _categoryId,
      weeklyTargetId: _targetId,
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
    final days = vm.weekDays;

    return SheetScaffold(
      title: 'Tugas Baru',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              controller: _titleCtrl,
              label: 'Tugas',
              hint: 'Contoh: Baca bab 2',
              prefixIcon: Icons.check_circle_outline_rounded,
              validator: requiredValidator,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            const Text('Hari', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final d in days)
                  ChoiceChip(
                    label: Text('${DateHelpers.shortDayName(d)} ${d.day}'),
                    selected: DateHelpers.isSameDay(d, _date),
                    onSelected: (_) => setState(() => _date = d),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Prioritas',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<TaskPriority>(
                showSelectedIcon: false,
                segments: [
                  for (final p in TaskPriority.values)
                    ButtonSegment(value: p, label: Text(p.label)),
                ],
                selected: {_priority},
                onSelectionChanged: (s) => setState(() => _priority = s.first),
              ),
            ),
            if (vm.categories.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Kategori',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final c in vm.categories)
                    ChoiceChip(
                      avatar: CircleAvatar(backgroundColor: c.color, radius: 5),
                      label: Text(c.name),
                      selected: _categoryId == c.id,
                      onSelected: (sel) =>
                          setState(() => _categoryId = sel ? c.id : null),
                    ),
                ],
              ),
            ],
            if (vm.weekTargets.isNotEmpty) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                initialValue: _targetId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Berkontribusi ke target (opsional)',
                  prefixIcon: Icon(Icons.track_changes_rounded),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Tanpa target'),
                  ),
                  for (final t in vm.weekTargets)
                    DropdownMenuItem<String?>(
                      value: t.id,
                      child: Text(t.title, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) => setState(() => _targetId = v),
              ),
            ],
            const SizedBox(height: 24),
            CustomButton(
              text: 'Tambah Tugas',
              onPressed: _submit,
              isLoading: vm.isMutating,
            ),
          ],
        ),
      ),
    );
  }
}
