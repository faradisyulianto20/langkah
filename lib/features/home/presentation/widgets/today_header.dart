import 'package:flutter/material.dart';
import 'package:langkah/core/constants/app_colors.dart';
import 'package:langkah/core/utils/date_helpers.dart';
import 'package:langkah/features/home/domain/home_messages.dart';
import 'package:percent_indicator/percent_indicator.dart';

/// Bagian atas Home: tanggal + streak, kalimat motivasi dinamis (tebal), dan
/// kartu gradien teal berisi ring progres serta 2 baris teks.
class TodayHeader extends StatelessWidget {
  final DateTime today;
  final int streak;
  final ({int done, int total}) progress;

  const TodayHeader({
    super.key,
    required this.today,
    required this.streak,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = progress.done;
    final total = progress.total;
    final complete = total > 0 && done >= total;
    final ratio = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);

    final dateLabel =
        '${DateHelpers.dayName(today)}, ${today.day} '
        '${DateHelpers.monthName(today.month)} ${today.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                dateLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: context.mutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  size: 20,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 4),
                Text(
                  '$streak hari',
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Kalimat motivasi dinamis: tebal, besar tapi tidak berlebihan.
        Text(
          HomeMessages.headline(done, total),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.tealPrimary, AppColors.tealDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.tealPrimary.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              CircularPercentIndicator(
                radius: 42,
                lineWidth: 9,
                percent: ratio,
                animation: true,
                animateFromLastPercent: true,
                circularStrokeCap: CircularStrokeCap.round,
                progressColor: Colors.white,
                backgroundColor: Colors.white24,
                center: complete
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 36,
                      )
                    : Text(
                        '${(ratio * 100).round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      HomeMessages.completedLabel(done, total),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      HomeMessages.remainingLabel(done, total),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
