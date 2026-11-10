import 'package:flutter/material.dart';
import 'package:langkah/core/constants/app_colors.dart';

/// Kotak menu tambahan di Home (Pomodoro, nanti Gym Tracker, dll):
/// minimalis, ikon di tengah atas dan nama fitur di bawahnya.
class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  /// Titik penanda kecil di sudut (mis. timer sedang berjalan).
  final bool active;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Di mode gelap pakai warna yang lebih terang agar ikon terbaca.
    final accent = context.isDarkMode
        ? Color.alphaBlend(Colors.white.withValues(alpha: 0.25), color)
        : color;

    return AspectRatio(
      aspectRatio: 1,
      child: Material(
        color: accent.withValues(alpha: context.isDarkMode ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(icon, color: accent, size: 28),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (active)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
