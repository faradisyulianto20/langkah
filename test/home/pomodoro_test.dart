import 'package:flutter_test/flutter_test.dart';
import 'package:langkah/features/home/data/pomodoro_notifier.dart';
import 'package:langkah/features/home/domain/pomodoro_rules.dart';
import 'package:langkah/features/home/presentation/pomodoro_controller.dart';

class FakeNotifier implements PomodoroNotifier {
  FakeNotifier({this.scheduling = true});

  final bool scheduling;
  final scheduled = <int, DateTime>{};
  final shown = <String>[];
  int permissionRequests = 0;

  @override
  bool get supportsScheduling => scheduling;
  @override
  Future<void> init() async {}
  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return true;
  }

  @override
  Future<void> schedule({
    required int id,
    required DateTime at,
    required String title,
    required String body,
  }) async => scheduled[id] = at;

  @override
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async => shown.add(title);

  @override
  Future<void> cancel(int id) async => scheduled.remove(id);
}

void main() {
  late DateTime now;
  late FakeNotifier notifier;
  late PomodoroController c;

  setUp(() {
    now = DateTime(2026, 11, 10, 9);
    notifier = FakeNotifier();
    c = PomodoroController(
      notifier: notifier,
      clock: () => now,
      autoTick: false,
    );
  });

  tearDown(() => c.dispose());

  test('istirahat otomatis mengikuti durasi fokus (tidak bisa diubah)', () {
    expect(PomodoroRules.breakFor(25), 5);
    expect(PomodoroRules.breakFor(50), 10);
    expect(PomodoroRules.breakFor(60), 10);
    // Durasi manual lain tetap mendapat istirahat otomatis.
    expect(PomodoroRules.breakFor(5), 5);
    expect(PomodoroRules.breakFor(30), 5);
    expect(PomodoroRules.breakFor(31), 10);
    expect(PomodoroRules.breakFor(75), 15);
    expect(PomodoroRules.breakFor(120), 20);
  });

  test('durasi fokus bisa diatur manual dalam batas 5-180 menit', () {
    c.setFocusMinutes(40);
    expect(c.focusMinutes, 40);
    expect(c.breakMinutes, 10);
    expect(c.remaining, const Duration(minutes: 40));

    c.setFocusMinutes(500);
    expect(c.focusMinutes, 180);
    c.setFocusMinutes(1);
    expect(c.focusMinutes, 5);
    expect(c.breakMinutes, 5);
  });

  test('mengatur durasi hanya saat idle', () async {
    c.setFocusMinutes(60);
    expect(c.remaining, const Duration(minutes: 60));

    await c.start();
    c.setFocusMinutes(25); // diabaikan saat berjalan
    expect(c.focusMinutes, 60);
  });

  test(
    'start meminta izin sekali & menjadwalkan notifikasi fokus+istirahat',
    () async {
      await c.start();
      expect(c.phase, PomodoroPhase.focus);
      expect(c.isRunning, isTrue);
      expect(notifier.permissionRequests, 1);
      expect(notifier.scheduled[1], now.add(const Duration(minutes: 25)));
      expect(notifier.scheduled[2], now.add(const Duration(minutes: 30)));

      await c.pause();
      await c.start();
      expect(notifier.permissionRequests, 1);
    },
  );

  test('fokus selesai → istirahat 5 menit otomatis → idle', () async {
    await c.start();

    now = now.add(const Duration(minutes: 25));
    await c.tick();
    expect(c.phase, PomodoroPhase.rest);
    expect(c.isRunning, isTrue);
    expect(c.remaining, const Duration(minutes: 5));
    expect(c.completedSessions, 1);
    expect(notifier.shown, contains('Fokus selesai'));

    now = now.add(const Duration(minutes: 5));
    await c.tick();
    expect(c.phase, PomodoroPhase.idle);
    expect(c.isRunning, isFalse);
    expect(notifier.shown, contains('Istirahat selesai'));
    expect(notifier.scheduled, isEmpty);
  });

  test('fokus manual 40 menit -> istirahat 10 menit', () async {
    c.setFocusMinutes(40);
    await c.start();
    now = now.add(const Duration(minutes: 40));
    await c.tick();
    expect(c.remaining, const Duration(minutes: 10));
  });

  test('jeda menyimpan sisa waktu & lanjut dari situ', () async {
    await c.start();
    now = now.add(const Duration(minutes: 10));
    await c.pause();
    expect(c.isPaused, isTrue);
    expect(c.remaining, const Duration(minutes: 15));
    expect(notifier.scheduled, isEmpty);

    now = now.add(const Duration(hours: 1)); // lama dijeda: tidak berkurang
    await c.start();
    expect(c.remaining, const Duration(minutes: 15));
    expect(notifier.scheduled[1], now.add(const Duration(minutes: 15)));
  });

  test(
    'aplikasi tertidur lewat fokus & istirahat: langsung idle, sesi dihitung',
    () async {
      await c.start();
      now = now.add(const Duration(minutes: 45)); // 25 fokus + 5 istirahat + 15
      await c.tick();
      expect(c.phase, PomodoroPhase.idle);
      expect(c.completedSessions, 1);
      expect(notifier.shown, isEmpty); // notifikasi terjadwal sudah berbunyi
    },
  );

  test(
    'aplikasi tertidur di tengah istirahat: sisa istirahat dihitung',
    () async {
      await c.start();
      now = now.add(const Duration(minutes: 27)); // fokus habis 2 menit lalu
      await c.tick();
      expect(c.phase, PomodoroPhase.rest);
      expect(c.remaining, const Duration(minutes: 3));
    },
  );

  test('reset kembali idle & membatalkan notifikasi', () async {
    await c.start();
    await c.reset();
    expect(c.phase, PomodoroPhase.idle);
    expect(c.remaining, const Duration(minutes: 25));
    expect(notifier.scheduled, isEmpty);
  });

  test(
    'platform tanpa penjadwalan tetap menampilkan notifikasi langsung',
    () async {
      final n = FakeNotifier(scheduling: false);
      final ctrl = PomodoroController(
        notifier: n,
        clock: () => now,
        autoTick: false,
      );
      await ctrl.start();
      now = now.add(const Duration(minutes: 27)); // fokus lewat 2 menit
      await ctrl.tick();
      expect(n.shown, contains('Fokus selesai'));
      ctrl.dispose();
    },
  );
}
