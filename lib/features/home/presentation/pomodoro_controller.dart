import 'dart:async';

import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:langkah/features/home/data/pomodoro_notifier.dart';
import 'package:langkah/features/home/domain/pomodoro_rules.dart';

enum PomodoroPhase { idle, focus, rest }

/// Mesin Pomodoro: fokus → istirahat otomatis → selesai.
///
/// Waktu dihitung dari `endAt` (bukan hitungan tick) sehingga tetap akurat
/// setelah aplikasi sempat di latar belakang.
class PomodoroController extends ChangeNotifier {
  PomodoroController({
    required this._notifier,
    DateTime Function()? clock,
    this._autoTick = true,
  }) : _clock = clock ?? DateTime.now {
    _remaining = _focus;
  }

  static const _focusEndId = 1;
  static const _restEndId = 2;

  final PomodoroNotifier _notifier;
  final DateTime Function() _clock;
  final bool _autoTick;

  int _focusMinutes = PomodoroRules.defaultFocusMinutes;
  PomodoroPhase _phase = PomodoroPhase.idle;
  bool _running = false;
  late Duration _remaining;
  DateTime? _endAt;
  int _sessions = 0;
  String? _taskTitle;
  bool _permissionAsked = false;
  Timer? _ticker;

  /// Durasi fokus (menit) yang diatur pengguna.
  int get focusMinutes => _focusMinutes;

  /// Durasi istirahat (menit): otomatis mengikuti fokus, tidak bisa diubah.
  int get breakMinutes => PomodoroRules.breakFor(_focusMinutes);

  Duration get _focus => Duration(minutes: _focusMinutes);
  Duration get _rest => Duration(minutes: breakMinutes);

  PomodoroPhase get phase => _phase;
  bool get isRunning => _running;
  bool get isPaused => _phase != PomodoroPhase.idle && !_running;
  Duration get remaining => _remaining;
  int get completedSessions => _sessions;
  String? get taskTitle => _taskTitle;

  Duration get _phaseTotal => switch (_phase) {
    PomodoroPhase.rest => _rest,
    _ => _focus,
  };

  /// 0..1: bagian fase yang sudah berlalu.
  double get progress {
    final total = _phaseTotal.inMilliseconds;
    if (total == 0) return 0;
    return (1 - _remaining.inMilliseconds / total).clamp(0.0, 1.0);
  }

  /// Mengatur durasi fokus (dibatasi 5-180 menit). Hanya saat idle;
  /// istirahat mengikuti otomatis.
  void setFocusMinutes(int minutes) {
    final value = PomodoroRules.clampFocus(minutes);
    if (_phase != PomodoroPhase.idle || _focusMinutes == value) return;
    _focusMinutes = value;
    _remaining = _focus;
    notifyListeners();
  }

  void setTask(String? title) {
    if (_taskTitle == title) return;
    _taskTitle = title;
    notifyListeners();
  }

  Future<void> start() async {
    if (_running) return;
    if (!_permissionAsked) {
      _permissionAsked = true;
      await _notifier.requestPermission();
    }
    if (_phase == PomodoroPhase.idle) {
      _phase = PomodoroPhase.focus;
      _remaining = _focus;
    }
    _endAt = _clock().add(_remaining);
    _running = true;
    await _scheduleNotifications();
    _startTicker();
    notifyListeners();
  }

  Future<void> pause() async {
    if (!_running) return;
    _syncRemaining();
    _running = false;
    _stopTicker();
    await _cancelNotifications();
    notifyListeners();
  }

  Future<void> reset() async {
    _stopTicker();
    await _cancelNotifications();
    _phase = PomodoroPhase.idle;
    _running = false;
    _endAt = null;
    _remaining = _focus;
    notifyListeners();
  }

  /// Hitung ulang sisa waktu; pindah fase bila sudah habis.
  /// Dipanggil timer tiap detik (dan langsung oleh tes).
  Future<void> tick() async {
    if (!_running || _endAt == null) return;
    final left = _endAt!.difference(_clock());
    if (left > Duration.zero) {
      _remaining = left;
      notifyListeners();
      return;
    }
    await _completePhase(overshoot: -left);
  }

  Future<void> _completePhase({required Duration overshoot}) async {
    // Notifikasi terjadwal bisa sudah berbunyi saat aplikasi di latar.
    final late = overshoot > const Duration(seconds: 5);
    final showHere = !late || !_notifier.supportsScheduling;

    if (_phase == PomodoroPhase.focus) {
      _sessions++;
      await _notifier.cancel(_focusEndId);
      if (overshoot >= _rest) {
        // Istirahat pun sudah lewat selama aplikasi tertidur.
        await _notifier.cancel(_restEndId);
        _toIdle();
        return;
      }
      if (showHere) {
        await _notifier.showNow(
          id: _focusEndId,
          title: 'Fokus selesai',
          body: 'Istirahat $breakMinutes menit dimulai otomatis.',
        );
      }
      _phase = PomodoroPhase.rest;
      _remaining = _rest - overshoot;
      _endAt = _clock().add(_remaining);
      await _notifier.cancel(_restEndId);
      await _notifier.schedule(
        id: _restEndId,
        at: _endAt!,
        title: 'Istirahat selesai',
        body: 'Siap fokus lagi?',
      );
      notifyListeners();
    } else {
      await _notifier.cancel(_restEndId);
      if (showHere) {
        await _notifier.showNow(
          id: _restEndId,
          title: 'Istirahat selesai',
          body: 'Siap fokus lagi?',
        );
      }
      _toIdle();
    }
  }

  void _toIdle() {
    _stopTicker();
    _phase = PomodoroPhase.idle;
    _running = false;
    _endAt = null;
    _remaining = _focus;
    notifyListeners();
  }

  void _syncRemaining() {
    if (_endAt == null) return;
    final left = _endAt!.difference(_clock());
    _remaining = left > Duration.zero ? left : Duration.zero;
  }

  Future<void> _scheduleNotifications() async {
    await _cancelNotifications();
    if (_endAt == null) return;
    if (_phase == PomodoroPhase.focus) {
      await _notifier.schedule(
        id: _focusEndId,
        at: _endAt!,
        title: 'Fokus selesai',
        body: 'Istirahat $breakMinutes menit dimulai otomatis.',
      );
      await _notifier.schedule(
        id: _restEndId,
        at: _endAt!.add(_rest),
        title: 'Istirahat selesai',
        body: 'Siap fokus lagi?',
      );
    } else {
      await _notifier.schedule(
        id: _restEndId,
        at: _endAt!,
        title: 'Istirahat selesai',
        body: 'Siap fokus lagi?',
      );
    }
  }

  Future<void> _cancelNotifications() async {
    await _notifier.cancel(_focusEndId);
    await _notifier.cancel(_restEndId);
  }

  void _startTicker() {
    _stopTicker();
    if (!_autoTick) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void dispose() {
    _stopTicker();
    super.dispose();
  }
}
