import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/foundation.dart';

/// Service for managing local notifications.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const int morningNotificationId = 1;
  static const int afternoonNotificationId = 2;
  static const int eveningNotificationId = 3;

  /// Initialize the notification service.
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz_data.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = timezoneInfo.identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      if (kDebugMode) {
        print('Error setting local timezone: $e. Falling back to UTC.');
      }
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(initSettings, onDidReceiveNotificationResponse: _onNotificationTap);

    _isInitialized = true;
  }

  /// Request notification permissions.
  Future<bool> requestPermissions() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      // For Android 13+, POST_NOTIFICATIONS is required
      final granted = await androidPlugin.requestNotificationsPermission();

      // Also ensure exact alarm is allowed on Android 12+
      // In a production app, you might want to check this and open settings if not allowed
      // for now we just return the notification permission status
      return granted ?? false;
    }

    final iosPlugin = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }

    return true;
  }

  /// Schedule a daily notification at the specified time.
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    bool repeatDaily = true,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'study_reminders_channel', // Changed ID to force update
          'Study Reminders',
          channelDescription: 'Daily reminders to practice vocabulary',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          fullScreenIntent: true, // Try to be more visible
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: repeatDaily ? DateTimeComponents.time : null,
    );

    if (kDebugMode) {
      print('--- NOTIFICATION SCHEDULED ---');
      print('ID: $id');
      print('Time: $scheduledDate');
      print('Local Timezone: ${tz.local.name}');
      print('Now: ${now.toString()}');
      print('------------------------------');
    }
  }

  /// Cancel a specific notification.
  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
    if (kDebugMode) {
      print('Cancelled notification $id');
    }
  }

  /// Cancel all notifications.
  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
    if (kDebugMode) {
      print('Cancelled all notifications');
    }
  }

  /// Handle notification tap.
  void _onNotificationTap(NotificationResponse response) {
    // The app will open automatically. You can add custom navigation here.
    if (kDebugMode) {
      print('Notification tapped: ${response.payload}');
    }
  }
}
