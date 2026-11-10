import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:langkah/core/constants/app_colors.dart';
import 'package:langkah/features/home/domain/pomodoro_rules.dart';
import 'package:langkah/features/home/presentation/home_view_model.dart';
import 'package:langkah/features/home/presentation/pomodoro_controller.dart';
import 'package:provider/provider.dart';

/// Halaman Pomodoro tersendiri (dibuka dari menu tambahan di Home).
///
/// Dibungkus provider yang sama dengan Home, sehingga timer tetap berjalan
/// walau halaman ini ditutup.
class PomodoroScreen extends StatelessWidget {
  const PomodoroScreen({super.key});

  static String format(Duration d) {
    final total = d.inSeconds < 0 ? 0 : d.inSeconds;
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<PomodoroController>();
    final theme = Theme.of(context);
    final isRest = c.phase == PomodoroPhase.rest;
    final accent = isRest ? AppColors.info : AppColors.tealPrimary;

    final phaseLabel = switch (c.phase) {
      PomodoroPhase.idle => 'Siap fokus',
      PomodoroPhase.focus => c.isRunning ? 'Fokus' : 'Fokus (dijeda)',
      PomodoroPhase.rest => c.isRunning ? 'Istirahat' : 'Istirahat (dijeda)',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Pomodoro')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    phaseLabel,
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    format(c.remaining),
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: c.phase == PomodoroPhase.idle ? 0 : c.progress,
                      minHeight: 8,
                      color: accent,
                      backgroundColor: context.trackColor,
                    ),
                  ),
                  if (c.completedSessions > 0) ...[
                    const SizedBox(height: 10),
                    Text(
                      '${c.completedSessions} sesi fokus selesai',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: c.isRunning ? c.pause : c.start,
                          icon: Icon(
                            c.isRunning
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                          ),
                          label: Text(
                            c.isRunning
                                ? 'Jeda'
                                : (c.isPaused ? 'Lanjutkan' : 'Mulai fokus'),
                          ),
                        ),
                      ),
                      if (c.phase != PomodoroPhase.idle) ...[
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: c.reset,
                          icon: Icon(
                            isRest
                                ? Icons.skip_next_rounded
                                : Icons.stop_rounded,
                          ),
                          label: Text(isRest ? 'Lewati' : 'Berhenti'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _TaskCard(controller: c),
          const SizedBox(height: 12),
          _DurationCard(controller: c),
        ],
      ),
    );
  }
}

/// Langkah yang sedang difokuskan.
class _TaskCard extends StatelessWidget {
  final PomodoroController controller;

  const _TaskCard({required this.controller});

  Future<void> _pick(BuildContext context) async {
    final vm = context.read<HomeViewModel>();
    final pending = vm.tasks.where((t) => !t.isCompleted).toList();
    final chosen = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: pending.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Tidak ada langkah yang belum selesai hari ini.'),
              )
            : ListView(
                shrinkWrap: true,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Pilih langkah untuk difokuskan',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  for (final t in pending)
                    ListTile(
                      leading: const Icon(Icons.check_circle_outline_rounded),
                      title: Text(t.title),
                      onTap: () => Navigator.pop(ctx, t.title),
                    ),
                ],
              ),
      ),
    );
    if (chosen != null) controller.setTask(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = controller.taskTitle;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.push_pin_outlined),
        title: Text(
          title ?? 'Belum ada langkah yang dipilih',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          title == null ? 'Opsional' : 'Fokus pada langkah ini',
          style: theme.textTheme.bodySmall,
        ),
        trailing: title == null
            ? TextButton(
                onPressed: () => _pick(context),
                child: const Text('Pilih'),
              )
            : IconButton(
                tooltip: 'Lepas langkah',
                icon: const Icon(Icons.close_rounded),
                onPressed: () => controller.setTask(null),
              ),
      ),
    );
  }
}

/// Pengaturan durasi: fokus bebas, istirahat otomatis dan terkunci.
class _DurationCard extends StatefulWidget {
  final PomodoroController controller;

  const _DurationCard({required this.controller});

  @override
  State<_DurationCard> createState() => _DurationCardState();
}

class _DurationCardState extends State<_DurationCard> {
  late final TextEditingController _text;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: '${widget.controller.focusMinutes}');
    widget.controller.addListener(_syncText);
    _focus.addListener(() {
      if (!_focus.hasFocus) _commit();
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncText);
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Samakan teks dengan nilai controller (chip/stepper), kecuali sedang
  /// diketik dengan nilai yang sama.
  void _syncText() {
    final value = '${widget.controller.focusMinutes}';
    if (_text.text != value &&
        int.tryParse(_text.text) != widget.controller.focusMinutes) {
      _text.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
  }

  /// Terapkan ketikan bila valid; rapikan teks saat selesai mengetik.
  void _apply(String raw) {
    final v = int.tryParse(raw);
    if (v == null) return;
    if (v >= PomodoroRules.minFocusMinutes &&
        v <= PomodoroRules.maxFocusMinutes) {
      widget.controller.setFocusMinutes(v);
    }
  }

  void _commit() {
    final v = int.tryParse(_text.text) ?? widget.controller.focusMinutes;
    widget.controller.setFocusMinutes(v);
    _text.text = '${widget.controller.focusMinutes}';
  }

  void _step(int delta) =>
      widget.controller.setFocusMinutes(widget.controller.focusMinutes + delta);

  @override
  Widget build(BuildContext context) {
    final c = context.watch<PomodoroController>();
    final theme = Theme.of(context);
    final enabled = c.phase == PomodoroPhase.idle;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Durasi fokus',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filledTonal(
                  tooltip: 'Kurangi 5 menit',
                  onPressed: enabled ? () => _step(-5) : null,
                  icon: const Icon(Icons.remove_rounded),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 150,
                  child: TextField(
                    controller: _text,
                    focusNode: _focus,
                    enabled: enabled,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      suffixText: 'mnt',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    onChanged: _apply,
                    onSubmitted: (_) => _commit(),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filledTonal(
                  tooltip: 'Tambah 5 menit',
                  onPressed: enabled ? () => _step(5) : null,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final m in PomodoroRules.quickPresets)
                  ChoiceChip(
                    label: Text('$m menit'),
                    selected: c.focusMinutes == m,
                    onSelected: enabled ? (_) => c.setFocusMinutes(m) : null,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'Atur ${PomodoroRules.minFocusMinutes}-'
                '${PomodoroRules.maxFocusMinutes} menit',
                style: theme.textTheme.bodySmall,
              ),
            ),
            const Divider(height: 28),
            Row(
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: context.mutedText,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Istirahat otomatis',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Text(
                  '${c.breakMinutes} menit',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.info,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Ditentukan otomatis dari durasi fokus dan tidak bisa diubah.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
