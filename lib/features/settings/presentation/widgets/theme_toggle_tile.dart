import 'package:flutter/material.dart';
import 'package:langkah/core/constants/app_colors.dart';
import 'package:langkah/core/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class ThemeToggleTile extends StatelessWidget {
  const ThemeToggleTile({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark;

    return Card(
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        secondary: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Icon(
            isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            key: ValueKey(isDark),
            color: isDark ? AppColors.tealLight : AppColors.warning,
            size: 24,
          ),
        ),
        title: Text(
          'Mode Gelap',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Text(
          isDark ? 'Tampilan gelap aktif' : 'Tampilan terang aktif',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        value: isDark,
        activeThumbColor: AppColors.tealPrimary,
        activeTrackColor: AppColors.tealLight,
        onChanged: (_) => themeProvider.toggleTheme(),
      ),
    );
  }
}
