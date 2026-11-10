import 'package:flutter/foundation.dart'
    show debugPrint, defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Abstraksi notifikasi Pomodoro (mudah diganti palsu saat tes).
abstract class PomodoroNotifier {
  /// true bila notifikasi bisa dijadwalkan agar tetap berbunyi saat aplikasi
  /// di latar belakang (Android/iOS). Di web/Windows hanya notifikasi langsung.
  bool get supportsScheduling;

  Future<void> init();

  /// Minta izin notifikasi. Panggil sebagai respons aksi pengguna.
  Future<bool> requestPermission();

  Future<void> schedule({
    required int id,
    required DateTime at,
    required String title,
    required String body,
  });

  Future<void> showNow({
    required int id,
    required String title,
    required String body,
  });

  Future<void> cancel(int id);
}

/// Implementasi nyata memakai `flutter_local_notifications`.
class LocalPomodoroNotifier implements PomodoroNotifier {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _channelId = 'pomodoro';
  static const _channelName = 'Pomodoro';

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Pengingat fokus dan istirahat Pomodoro',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
    macOS: DarwinNotificationDetails(),
    windows: WindowsNotificationDetails(),
    web: WebNotificationDetails(),
  );

  bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  bool get supportsScheduling => _isMobile;

  @override
  Future<void> init() async {
    if (_ready) return;
    try {
      tzdata.initializeTimeZones();
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
          macOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
          windows: WindowsInitializationSettings(
            appName: 'Langkah',
            appUserModelId: 'com.example.langkah',
            guid: '6f1d5c1e-3a52-4f1b-9d0b-4c1a8f7a2b19',
          ),
          web: WebInitializationSettings(),
        ),
      );
      _ready = true;
    } catch (e) {
      debugPrint('[PomodoroNotifier] init gagal: $e');
    }
  }

  @override
  Future<bool> requestPermission() async {
    await init();
    if (!_ready) return false;
    try {
      if (kIsWeb) {
        return await _plugin
                .resolvePlatformSpecificImplementation<
                  WebFlutterLocalNotificationsPlugin
                >()
                ?.requestNotificationsPermission() ??
            false;
      }
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          return await _plugin
                  .resolvePlatformSpecificImplementation<
                    AndroidFlutterLocalNotificationsPlugin
                  >()
                  ?.requestNotificationsPermission() ??
              false;
        case TargetPlatform.iOS:
          return await _plugin
                  .resolvePlatformSpecificImplementation<
                    IOSFlutterLocalNotificationsPlugin
                  >()
                  ?.requestPermissions(alert: true, badge: true, sound: true) ??
              false;
        default:
          return true; // Windows tidak memerlukan izin runtime.
      }
    } catch (e) {
      debugPrint('[PomodoroNotifier] izin gagal: $e');
      return false;
    }
  }

  @override
  Future<void> schedule({
    required int id,
    required DateTime at,
    required String title,
    required String body,
  }) async {
    if (!supportsScheduling) return;
    await init();
    if (!_ready) return;
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(at, tz.UTC),
        notificationDetails: _details,
        // Tidak memerlukan izin alarm tepat; bisa tertunda sedikit saat Doze.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('[PomodoroNotifier] jadwal gagal: $e');
    }
  }

  @override
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    await init();
    if (!_ready) return;
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: _details,
      );
    } catch (e) {
      debugPrint('[PomodoroNotifier] tampil gagal: $e');
    }
  }

  @override
  Future<void> cancel(int id) async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: id);
    } catch (e) {
      debugPrint('[PomodoroNotifier] batal gagal: $e');
    }
  }
}
