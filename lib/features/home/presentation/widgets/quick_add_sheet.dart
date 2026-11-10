import 'package:flutter/material.dart';
import 'package:langkah/core/utils/ui_feedback.dart';
import 'package:langkah/core/widgets/custom_button.dart';
import 'package:langkah/core/widgets/custom_text_field.dart';
import 'package:langkah/features/home/domain/daily_task.dart';
import 'package:langkah/features/home/presentation/home_view_model.dart';
import 'package:provider/provider.dart';

/// Membuka sheet tambah cepat / edit dengan [HomeViewModel] yang sama.
Future<void> showQuickAddSheet(BuildContext context, {DailyTask? task}) {
  final vm = context.read<HomeViewModel>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => ChangeNotifierProvider.value(
      value: vm,
      child: QuickAddSheet(task: task),
    ),
  );
}

/// Tambah cepat (hari ini / backlog) atau edit langkah hari ini.
class QuickAddSheet extends StatefulWidget {
  final DailyTask? task;

  const QuickAddSheet({super.key, this.task});

  @override
  State<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<QuickAddSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late TaskPriority _priority;
  String? _categoryId;
  QuickAddTarget _target = QuickAddTarget.today;

  bool get _isEdit => widget.task != null;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleCtrl = TextEditingController(text: t?.title ?? '');
    _priority = t?.priority ?? TaskPriority.medium;
    _categoryId = t?.categoryId;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  String? _validateTitle(String? v) {
    if (v == null || v.trim().isEmpty) return 'Judul wajib diisi';
    if (v.trim().length > 120) return 'Judul maksimal 120 karakter';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = context.read<HomeViewModel>();
    final task = widget.task;
    final ok = task == null
        ? await vm.quickAdd(
            title: _titleCtrl.text,
            target: _target,
            priority: _priority,
            categoryId: _categoryId,
          )
        : await vm.updateTask(
            task,
            title: _titleCtrl.text,
            priority: _priority,
            categoryId: _categoryId,
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
    final vm = context.watch<HomeViewModel>();
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEdit ? 'Edit Langkah' : 'Langkah Baru',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _titleCtrl,
              label: 'Langkah',
              hint: 'Contoh: Baca 10 halaman',
              prefixIcon: Icons.check_circle_outline_rounded,
              validator: _validateTitle,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
            ),
            if (!_isEdit) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<QuickAddTarget>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: QuickAddTarget.today,
                      label: Text('Hari Ini'),
                      icon: Icon(Icons.today_rounded),
                    ),
                    ButtonSegment(
                      value: QuickAddTarget.backlog,
                      label: Text('Backlog'),
                      icon: Icon(Icons.inbox_outlined),
                    ),
                  ],
                  selected: {_target},
                  onSelectionChanged: (s) => setState(() => _target = s.first),
                ),
              ),
            ],
            if (_isEdit || _target == QuickAddTarget.today) ...[
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
                  onSelectionChanged: (s) =>
                      setState(() => _priority = s.first),
                ),
              ),
            ],
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
            const SizedBox(height: 24),
            CustomButton(
              text: _isEdit ? 'Simpan' : 'Tambah',
              onPressed: _submit,
              isLoading: vm.isMutating,
            ),
          ],
        ),
      ),
    );
  }
}
