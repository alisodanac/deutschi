import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

/// Service for managing local notifications.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  bool _permissionsGranted = false;
  bool _canUseExactAlarms = false;

  static const int morningNotificationId = 1;
  static const int afternoonNotificationId = 2;
  static const int eveningNotificationId = 3;

  /// Initialize the notification service.
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz_data.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone().timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw 'Timezone timeout',
      );
      final String timeZoneName = timezoneInfo.identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('Timezone set to: $timeZoneName');
    } catch (e) {
      debugPrint('Error setting local timezone: $e. Falling back to UTC.');
      // Fallback to a known timezone
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {
        // tz.local will default
      }
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(initSettings, onDidReceiveNotificationResponse: _onNotificationTap);

    // Create the notification channel explicitly for Android
    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'study_reminders_channel',
            'Study Reminders',
            description: 'Daily reminders to practice vocabulary',
            importance: Importance.max,
          ),
        );
      }
    }

    _isInitialized = true;
    debugPrint('NotificationService initialized successfully');
  }

  /// Request notification permissions.
  /// Returns true if permissions are granted.
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        // Request POST_NOTIFICATIONS permission for Android 13+
        final granted = await androidPlugin.requestNotificationsPermission();
        _permissionsGranted = granted ?? false;

        // Check if exact alarms are available (don't open settings, just check)
        try {
          _canUseExactAlarms = await androidPlugin.canScheduleExactNotifications() ?? false;
        } catch (e) {
          _canUseExactAlarms = false;
        }

        debugPrint(
          'Android notification permission: $_permissionsGranted, exact alarms available: $_canUseExactAlarms',
        );
        return _permissionsGranted;
      }
    }

    if (Platform.isIOS) {
      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(alert: true, badge: true, sound: true);
        _permissionsGranted = granted ?? false;
        _canUseExactAlarms = true; // iOS handles this differently
        debugPrint('iOS notification permission: $_permissionsGranted');
        return _permissionsGranted;
      }
    }

    _permissionsGranted = true;
    _canUseExactAlarms = true;
    return true;
  }

  /// Returns the appropriate schedule mode based on available permissions.
  AndroidScheduleMode _getScheduleMode() {
    if (_canUseExactAlarms) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }
    // Fallback: inexact mode doesn't require SCHEDULE_EXACT_ALARM permission
    // Notifications may be delayed by a few minutes at most
    debugPrint('Using inexact alarm mode (exact alarms not permitted)');
    return AndroidScheduleMode.inexactAllowWhileIdle;
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
    // Ensure permissions are granted before scheduling
    if (!_permissionsGranted) {
      final granted = await requestPermissions();
      if (!granted) {
        debugPrint('Cannot schedule notification $id: permissions not granted');
        return;
      }
    }

    // Cancel existing notification with same ID first
    await _plugin.cancel(id);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'study_reminders_channel',
            'Study Reminders',
            channelDescription: 'Daily reminders to practice vocabulary',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            icon: '@mipmap/launcher_icon',
          ),
          iOS: const DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
        ),
        androidScheduleMode: _getScheduleMode(),
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: repeatDaily ? DateTimeComponents.time : null,
      );

      debugPrint('--- NOTIFICATION SCHEDULED ---');
      debugPrint('ID: $id');
      debugPrint('Scheduled for: $scheduledDate');
      debugPrint('Local Timezone: ${tz.local.name}');
      debugPrint('Now: ${now.toString()}');
      debugPrint('Repeat daily: $repeatDaily');
      debugPrint('------------------------------');
    } catch (e) {
      debugPrint('Error scheduling notification $id: $e');
    }
  }

  /// Cancel a specific notification.
  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
    debugPrint('Cancelled notification $id');
  }

  /// Cancel all notifications.
  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
    debugPrint('Cancelled all notifications');
  }

  /// Get all pending notifications (useful for debugging).
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _plugin.pendingNotificationRequests();
  }

  /// Show a test notification immediately (for debugging).
  Future<void> showTestNotification() async {
    if (!_permissionsGranted) {
      final granted = await requestPermissions();
      if (!granted) {
        debugPrint('Cannot show test notification: permissions not granted');
        return;
      }
    }

    try {
      await _plugin.show(
        999,
        'Test Notification 🔔',
        'If you see this, notifications are working!',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'study_reminders_channel',
            'Study Reminders',
            channelDescription: 'Daily reminders to practice vocabulary',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/launcher_icon',
          ),
          iOS: const DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
        ),
      );
      debugPrint('Test notification sent successfully');
    } catch (e) {
      debugPrint('Error sending test notification: $e');
    }
  }

  /// Show a test scheduled notification 10 seconds from now.
  /// Uses a Dart Timer + show() as a reliable fallback to test the pipeline,
  /// and also attempts zonedSchedule to test the alarm system.
  Future<void> showScheduledTestNotification() async {
    if (!_permissionsGranted) {
      final granted = await requestPermissions();
      if (!granted) {
        debugPrint('Cannot show scheduled test: permissions not granted');
        return;
      }
    }

    debugPrint('=== SCHEDULING DIAGNOSTIC ===');
    debugPrint('Can use exact alarms: $_canUseExactAlarms');
    debugPrint('Schedule mode: ${_getScheduleMode()}');
    debugPrint('Local timezone: ${tz.local.name}');
    debugPrint('TZ now: ${tz.TZDateTime.now(tz.local)}');

    // Method 1: Use a Dart Timer as a reliable 10-second test
    // This bypasses AlarmManager entirely and proves the notification pipeline works
    Future.delayed(const Duration(seconds: 10), () async {
      try {
        await _plugin.show(
          997,
          'Timer Test ⏱️',
          'This notification was triggered by a Dart Timer (10s delay)',
          NotificationDetails(
            android: AndroidNotificationDetails(
              'study_reminders_channel',
              'Study Reminders',
              channelDescription: 'Daily reminders to practice vocabulary',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/launcher_icon',
            ),
            iOS: const DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
          ),
        );
        debugPrint('Timer-based test notification fired successfully');
      } catch (e) {
        debugPrint('Timer-based test notification error: $e');
      }
    });

    // Method 2: Also try zonedSchedule to test the alarm system
    try {
      final scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 15));

      // Try exact mode first, catch and fall back if it fails
      try {
        await _plugin.zonedSchedule(
          998,
          'Alarm Test 🔔',
          'This notification was triggered by AlarmManager (15s delay)',
          scheduledDate,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'study_reminders_channel',
              'Study Reminders',
              channelDescription: 'Daily reminders to practice vocabulary',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/launcher_icon',
            ),
            iOS: const DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
        debugPrint('zonedSchedule (exact) set for: $scheduledDate');
      } catch (exactError) {
        debugPrint('Exact alarm failed: $exactError');
        debugPrint('Trying inexact mode...');

        await _plugin.zonedSchedule(
          998,
          'Alarm Test 🔔',
          'This notification was triggered by AlarmManager (inexact, 15s delay)',
          scheduledDate,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'study_reminders_channel',
              'Study Reminders',
              channelDescription: 'Daily reminders to practice vocabulary',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/launcher_icon',
            ),
            iOS: const DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
        debugPrint('zonedSchedule (inexact) set for: $scheduledDate');
      }

      // List pending to verify
      final pending = await _plugin.pendingNotificationRequests();
      debugPrint('Pending notifications after scheduling: ${pending.length}');
      for (final p in pending) {
        debugPrint('  Pending: id=${p.id}, title=${p.title}');
      }
    } catch (e, stack) {
      debugPrint('zonedSchedule completely failed: $e');
      debugPrint('Stack: $stack');
    }
    debugPrint('=== END DIAGNOSTIC ===');
  }

  /// Handle notification tap.
  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }
}
