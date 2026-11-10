/// Aturan Pomodoro. Durasi fokus bebas diatur pengguna; durasi istirahat
/// SELALU otomatis mengikuti durasi fokus dan tidak bisa diubah:
///
/// - fokus ≤ 30 menit → istirahat 5 menit   (mis. 25 → 5)
/// - fokus ≤ 60 menit → istirahat 10 menit  (mis. 50 → 10, 60 → 10)
/// - fokus ≤ 90 menit → istirahat 15 menit
/// - fokus > 90 menit → istirahat 20 menit
class PomodoroRules {
  PomodoroRules._();

  static const int minFocusMinutes = 5;
  static const int maxFocusMinutes = 180;
  static const int defaultFocusMinutes = 25;

  /// Pilihan cepat (tetap bisa diatur manual di luar daftar ini).
  static const List<int> quickPresets = [25, 50, 60];

  static int breakFor(int focusMinutes) {
    if (focusMinutes <= 30) return 5;
    if (focusMinutes <= 60) return 10;
    if (focusMinutes <= 90) return 15;
    return 20;
  }

  static int clampFocus(int minutes) =>
      minutes.clamp(minFocusMinutes, maxFocusMinutes);
}
