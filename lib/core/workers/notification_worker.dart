import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

const notificationTaskName = 'check_reminders';

/// Called by WorkManager to check if any reminder should fire.
/// This runs periodically (~15 min) and checks if any reminder time
/// has been reached since the last check.
Future<bool> executeNotificationTask() async {
  try {
    final prefs = await SharedPreferences.getInstance();

    // Check if notifications are enabled
    final enabled = prefs.getBool('notification_enabled') ?? false;
    if (!enabled) return true;

    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    // Get the last check time to avoid duplicate notifications
    final lastCheckStr = prefs.getString('last_notification_check');
    final lastCheck = lastCheckStr != null ? DateTime.tryParse(lastCheckStr) : null;
    final lastCheckMinutes = lastCheck != null ? lastCheck.hour * 60 + lastCheck.minute : -1;

    // Only check if at least 10 minutes have passed since last check (avoid rapid re-fires)
    if (lastCheck != null && now.difference(lastCheck).inMinutes < 10) {
      return true;
    }

    // Save current check time
    await prefs.setString('last_notification_check', now.toIso8601String());

    // Initialize the notification plugin (lightweight, no timezone needed)
    final plugin = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const initSettings = InitializationSettings(android: androidSettings);
    await plugin.initialize(initSettings);

    // Check each reminder type
    final repeatDaily = prefs.getBool('repeat_daily') ?? true;

    // Morning reminder
    if (prefs.getBool('morning_enabled') ?? true) {
      final hour = prefs.getInt('morning_hour') ?? 9;
      final minute = prefs.getInt('morning_minute') ?? 0;
      await _checkAndFireReminder(
        plugin: plugin,
        prefs: prefs,
        id: 1,
        hour: hour,
        minute: minute,
        currentMinutes: currentMinutes,
        lastCheckMinutes: lastCheckMinutes,
        title: 'Zeit zum Lernen! 📚',
        body: 'Good morning! Time to practice your German vocabulary.',
        prefKey: 'last_morning_notification',
        now: now,
        repeatDaily: repeatDaily,
      );
    }

    // Afternoon reminder
    if (prefs.getBool('afternoon_enabled') ?? false) {
      final hour = prefs.getInt('afternoon_hour') ?? 14;
      final minute = prefs.getInt('afternoon_minute') ?? 0;
      await _checkAndFireReminder(
        plugin: plugin,
        prefs: prefs,
        id: 2,
        hour: hour,
        minute: minute,
        currentMinutes: currentMinutes,
        lastCheckMinutes: lastCheckMinutes,
        title: 'Zeit zum Lernen! 📚',
        body: 'Afternoon break? Perfect time for a quick vocabulary session!',
        prefKey: 'last_afternoon_notification',
        now: now,
        repeatDaily: repeatDaily,
      );
    }

    // Evening reminder
    if (prefs.getBool('evening_enabled') ?? false) {
      final hour = prefs.getInt('evening_hour') ?? 19;
      final minute = prefs.getInt('evening_minute') ?? 0;
      await _checkAndFireReminder(
        plugin: plugin,
        prefs: prefs,
        id: 3,
        hour: hour,
        minute: minute,
        currentMinutes: currentMinutes,
        lastCheckMinutes: lastCheckMinutes,
        title: 'Zeit zum Lernen! 📚',
        body: 'Wind down with some German practice before bed.',
        prefKey: 'last_evening_notification',
        now: now,
        repeatDaily: repeatDaily,
      );
    }

    // Custom reminders
    final customRemindersJson = prefs.getString('custom_reminders');
    if (customRemindersJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(customRemindersJson);
        for (final r in decoded) {
          final id = r['id'] as int;
          final reminderEnabled = r['enabled'] as bool? ?? true;
          if (!reminderEnabled) continue;

          final hour = r['hour'] as int;
          final minute = r['minute'] as int;
          await _checkAndFireReminder(
            plugin: plugin,
            prefs: prefs,
            id: id,
            hour: hour,
            minute: minute,
            currentMinutes: currentMinutes,
            lastCheckMinutes: lastCheckMinutes,
            title: 'Zeit zum Lernen! 📚',
            body: 'Time for your custom vocabulary practice session!',
            prefKey: 'last_custom_${id}_notification',
            now: now,
            repeatDaily: repeatDaily,
          );
        }
      } catch (e) {
        // Ignore parse errors
      }
    }

    return true;
  } catch (e) {
    print('Notification worker error: $e');
    return false;
  }
}

/// Check if a reminder's time has been reached and fire the notification.
/// Uses a 20-minute window to account for WorkManager's imprecise timing.
Future<void> _checkAndFireReminder({
  required FlutterLocalNotificationsPlugin plugin,
  required SharedPreferences prefs,
  required int id,
  required int hour,
  required int minute,
  required int currentMinutes,
  required int lastCheckMinutes,
  required String title,
  required String body,
  required String prefKey,
  required DateTime now,
  required bool repeatDaily,
}) async {
  final reminderMinutes = hour * 60 + minute;

  // Check if current time is within a 20-minute window after the reminder time
  final minutesSinceReminder = currentMinutes - reminderMinutes;
  if (minutesSinceReminder < 0 || minutesSinceReminder > 20) {
    return; // Not in the firing window
  }

  // Check if we already fired this notification today
  final lastFiredStr = prefs.getString(prefKey);
  if (lastFiredStr != null) {
    final lastFired = DateTime.tryParse(lastFiredStr);
    if (lastFired != null) {
      final sameDay = lastFired.year == now.year && lastFired.month == now.month && lastFired.day == now.day;
      if (sameDay) {
        return; // Already fired today
      }
    }
  }

  // Fire the notification!
  await plugin.show(
    id,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        'study_reminders_channel',
        'Study Reminders',
        channelDescription: 'Daily reminders to practice vocabulary',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/launcher_icon',
      ),
    ),
  );

  // Record that we fired this notification
  await prefs.setString(prefKey, now.toIso8601String());
  print('Notification worker: Fired reminder $id ($title) at ${now.toIso8601String()}');
}
