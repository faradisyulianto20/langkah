import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Palette
  static const Color tealPrimary = Color(0xFF00897B);
  static const Color tealLight = Color(0xFF4EBaaa);
  static const Color tealDark = Color(0xFF005B4F);

  // Background & Surfaces
  static const Color canvasLight = Color(0xFFF8F9FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color canvasDark = Color(0xFF0F1415);
  static const Color surfaceDark = Color(0xFF182022);

  // Neutrals & Text
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFFFAFAFA);
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFEEEEEE);

  // Status & Priority
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFB8C00);
  static const Color info = Color(0xFF1E88E5);

  // Dark mode: teks sekunder, garis, dan trek bar yang nyaman di latar gelap.
  static const Color textSecondaryDark = Color(0xFF9FB0B5);
  static const Color borderDark = Color(0xFF2A3A3D);
  static const Color trackDark = Color(0xFF2B3A3D);
  static const Color navDark = Color(0xFF121A1C);

  /// Warna progres dinamis: 0% merah, 50% oranye, 100% hijau
  /// (diinterpolasi di antaranya). [ratio] null = belum ada data (netral).
  static Color progressColor(double? ratio) {
    if (ratio == null) return textSecondary;
    final r = ratio.clamp(0.0, 1.0);
    return r < 0.5
        ? Color.lerp(error, warning, r / 0.5)!
        : Color.lerp(warning, success, (r - 0.5) / 0.5)!;
  }

  // Category Accent Colors
  static const Color catCoding = Color(0xFF00897B);
  static const Color catFitness = Color(0xFFFB8C00);
  static const Color catHabit = Color(0xFF1E88E5);
  static const Color catLearning = Color(0xFF8E24AA);
}

/// Warna yang menyesuaikan mode terang/gelap. Pakai ini (bukan konstanta
/// `AppColors.*` yang hanya cocok untuk mode terang) di widget.
extension AppThemeColors on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Teks/ikon sekunder (samar).
  Color get mutedText =>
      isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary;

  /// Garis tepi & pemisah.
  Color get borderColor => isDarkMode ? AppColors.borderDark : AppColors.border;

  /// Latar kosong bar progres.
  Color get trackColor => isDarkMode ? AppColors.trackDark : AppColors.divider;
}
