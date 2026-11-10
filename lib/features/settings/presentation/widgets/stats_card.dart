import 'package:flutter/material.dart';
import 'package:langkah/core/constants/app_colors.dart';
import 'package:langkah/features/settings/domain/streak_data.dart';

class StatsCard extends StatelessWidget {
  final StreakData stats;

  const StatsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.bar_chart_rounded,
                  color: AppColors.tealPrimary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Statistik Langkah',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.local_fire_department_rounded,
                    iconColor: AppColors.warning,
                    value: '${stats.effectiveCurrentStreak(DateTime.now())}',
                    label: 'Streak\nSekarang',
                    unit: 'hari',
                  ),
                ),
                _buildDivider(context),
                Expanded(
                  child: _StatItem(
                    icon: Icons.emoji_events_rounded,
                    iconColor: const Color(0xFFFFB300),
                    value: '${stats.longestStreak}',
                    label: 'Streak\nTerpanjang',
                    unit: 'hari',
                  ),
                ),
                _buildDivider(context),
                Expanded(
                  child: _StatItem(
                    icon: Icons.check_circle_rounded,
                    iconColor: AppColors.success,
                    value: '${stats.totalCompletedSteps}',
                    label: 'Total\nLangkah',
                    unit: 'selesai',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      width: 1,
      height: 56,
      color: context.trackColor,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final String unit;

  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 26),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          unit,
          style: TextStyle(fontSize: 11, color: context.mutedText),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: context.mutedText,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}
