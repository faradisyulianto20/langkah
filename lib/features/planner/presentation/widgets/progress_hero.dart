import 'package:flutter/material.dart';
import 'package:langkah/core/constants/app_colors.dart';

typedef Progress = ({int done, int total});

/// Kartu progres utama di puncak halaman Planner: gradien teal, teks putih,
/// angka `x/y`, bar progres, dan kalimat penyemangat.
class ProgressHero extends StatelessWidget {
  final String title;
  final String unit;
  final Progress progress;
  final String? secondaryLabel;
  final Progress? secondary;
  final String emptyHint;

  const ProgressHero({
    super.key,
    required this.title,
    required this.unit,
    required this.progress,
    required this.emptyHint,
    this.secondaryLabel,
    this.secondary,
  });

  static double _ratioOf(Progress p) =>
      p.total == 0 ? 0 : (p.done / p.total).clamp(0, 1).toDouble();

  double get _ratio => _ratioOf(progress);
  bool get _complete => progress.total > 0 && progress.done >= progress.total;

  String get _message {
    if (progress.total == 0) return emptyHint;
    if (_complete) return 'Luar biasa, semuanya selesai!';
    if (_ratio >= 0.75) return 'Hampir sampai, tinggal sedikit lagi!';
    if (_ratio >= 0.5) return 'Sudah lebih dari separuh, pertahankan!';
    if (_ratio > 0) return 'Awal yang bagus, terus melangkah!';
    return 'Mulai dari satu langkah kecil hari ini.';
  }

  @override
  Widget build(BuildContext context) {
    const onHero = Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.tealPrimary, AppColors.tealDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: onHero,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${progress.done}/${progress.total}',
                style: const TextStyle(
                  color: onHero,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  unit,
                  style: const TextStyle(color: onHero, fontSize: 14),
                ),
              ),
              const Spacer(),
              if (_complete)
                const Icon(Icons.check_circle_rounded, color: onHero, size: 28)
              else
                Text(
                  '${(_ratio * 100).round()}%',
                  style: const TextStyle(
                    color: onHero,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _ratio,
              minHeight: 10,
              color: Colors.white,
              backgroundColor: Colors.white24,
            ),
          ),
          const SizedBox(height: 10),
          Text(_message, style: const TextStyle(color: onHero, fontSize: 13)),
          if (secondary != null && secondaryLabel != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    secondaryLabel!,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
                Text(
                  '${secondary!.done}/${secondary!.total}',
                  style: const TextStyle(
                    color: onHero,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: _ratioOf(secondary!),
                minHeight: 4,
                color: Colors.white70,
                backgroundColor: Colors.white24,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
