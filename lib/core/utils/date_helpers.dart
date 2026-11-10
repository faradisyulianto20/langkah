/// Helper tanggal (tanpa dependensi locale) untuk Planner.
class DateHelpers {
  DateHelpers._();

  static const _months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];
  static const _days = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime firstOfMonth(DateTime d) => DateTime(d.year, d.month, 1);

  /// Senin dari minggu yang memuat [d].
  static DateTime startOfWeek(DateTime d) =>
      DateTime(d.year, d.month, d.day - (d.weekday - 1));

  static DateTime endOfWeek(DateTime d) {
    final s = startOfWeek(d);
    return DateTime(s.year, s.month, s.day + 6);
  }

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Jumlah minggu ISO dalam [year] (52 atau 53).
  /// 28 Desember selalu berada di minggu terakhir tahun ISO.
  static int isoWeeksInYear(int year) => isoWeek(DateTime(year, 12, 28)).week;

  /// Nomor minggu & tahun ISO-8601 (minggu dimulai Senin).
  static ({int year, int week}) isoWeek(DateTime d) {
    final date = DateTime.utc(d.year, d.month, d.day);
    final thursday = date.add(Duration(days: 4 - date.weekday));
    final jan1 = DateTime.utc(thursday.year, 1, 1);
    final week = (thursday.difference(jan1).inDays / 7).floor() + 1;
    return (year: thursday.year, week: week);
  }

  /// `YYYY-MM-DD` untuk kolom DATE di Postgres.
  static String toSqlDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static DateTime? parseSqlDate(Object? value) {
    if (value is! String) return null;
    final parsed = DateTime.tryParse(value);
    return parsed == null ? null : dateOnly(parsed);
  }

  static String monthName(int month) => _months[month - 1];

  static String dayName(DateTime d) => _days[d.weekday - 1];

  static String shortDayName(DateTime d) =>
      _days[d.weekday - 1].substring(0, 3);

  /// Contoh: `November 2026`.
  static String monthLabel(DateTime d) => '${monthName(d.month)} ${d.year}';

  /// Contoh: `10 Nov`.
  static String shortDate(DateTime d) =>
      '${d.day} ${monthName(d.month).substring(0, 3)}';

  /// Contoh: `9 Nov – 15 Nov`.
  static String weekRangeLabel(DateTime start) {
    final end = DateTime(start.year, start.month, start.day + 6);
    return '${shortDate(start)} – ${shortDate(end)}';
  }
}
