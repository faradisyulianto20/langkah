/// Teks dinamis Home berdasarkan jumlah langkah selesai dari total.
class HomeMessages {
  HomeMessages._();

  /// Kalimat motivasi utama (tebal, di bagian atas).
  static String headline(int done, int total) {
    if (total <= 0) return 'Mulai hari ini dengan satu langkah kecil';
    final remaining = total - done;
    if (done <= 0) {
      return total == 1
          ? 'Satu langkah menunggumu, mulai sekarang'
          : '$total langkah menunggumu, mulai dari yang termudah';
    }
    if (remaining <= 0) {
      return total == 1
          ? 'Langkahmu hari ini tuntas, kerja bagus!'
          : 'Semua $total langkah tuntas, kerja bagus!';
    }
    if (remaining == 1) return 'Tinggal satu langkah lagi, ayo selesaikan!';
    if (done * 2 >= total) {
      return 'Sudah $done langkah, tinggal $remaining lagi. Sedikit lagi!';
    }
    return 'Awal yang bagus, $done langkah selesai. Terus lanjut!';
  }

  /// Baris tebal di kartu progres, mis. `2 langkah selesai`.
  static String completedLabel(int done, int total) =>
      total <= 0 ? 'Belum ada langkah' : '$done langkah selesai';

  /// Baris kecil samar di bawahnya, mis. `sisa 3 langkah lagi`.
  static String remainingLabel(int done, int total) {
    if (total <= 0) return 'Tambahkan langkah pertamamu';
    final remaining = total - done;
    if (remaining <= 0) return 'Semua langkah hari ini tuntas';
    return 'sisa $remaining langkah lagi';
  }
}
