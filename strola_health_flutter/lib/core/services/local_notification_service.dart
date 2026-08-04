import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:strola_health/domain/entities/app_notification.dart';

/// Wraps `flutter_local_notifications` — OS-level banners for the in-app
/// notification feed. Static-method pattern, mirroring `WidgetService`.
class LocalNotificationService {
  LocalNotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const String _channelId = 'strolla_general';
  static const String _channelName = 'Strolla notifications';
  static const String _channelDescription =
      'Goal, streak, challenge, community and device alerts';
  static const int _goalReminderNotificationId = 1000001;

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// Must be called once at app startup, before any other method here.
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    tz_data.initializeTimeZones();
    final localTimezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTimezone));

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      ),
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
      ),
    );
    await androidPlugin?.requestNotificationsPermission();
  }

  /// Fires an instant OS notification for [notification].
  static Future<void> showNow(AppNotification notification) {
    return _plugin.show(
      notification.id.hashCode,
      notification.title,
      notification.body,
      _details,
    );
  }

  /// Schedules (replacing any pending one) today/tomorrow's 7pm goal
  /// reminder with the latest snapshot of [body]. Uses
  /// `inexactAllowWhileIdle` rather than an exact alarm — a few minutes of
  /// slack on a once-daily evening nudge isn't worth requesting Android's
  /// sensitive "schedule exact alarms" permission for.
  static Future<void> scheduleGoalReminder({
    required String title,
    required String body,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var fireAt = tz.TZDateTime(tz.local, now.year, now.month, now.day, 19);
    if (!fireAt.isAfter(now)) {
      fireAt = fireAt.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      _goalReminderNotificationId,
      title,
      body,
      fireAt,
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelGoalReminder() =>
      _plugin.cancel(_goalReminderNotificationId);
}
