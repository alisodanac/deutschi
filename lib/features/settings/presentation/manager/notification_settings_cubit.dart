import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/workers/notification_worker.dart';
import '../../domain/entities/custom_reminder.dart';
import 'notification_settings_state.dart';

class NotificationSettingsCubit extends Cubit<NotificationSettingsState> {
  final NotificationService notificationService;

  NotificationSettingsCubit(this.notificationService) : super(const NotificationSettingsState());

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final customRemindersJson = prefs.getString('custom_reminders');
    List<CustomReminder> customReminders = [];
    if (customRemindersJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(customRemindersJson);
        customReminders = decoded.map((e) => CustomReminder.fromJson(e)).toList();
      } catch (e) {
        // Handle error or reset
      }
    }

    emit(
      NotificationSettingsState(
        enabled: prefs.getBool('notification_enabled') ?? false,
        repeatDaily: prefs.getBool('repeat_daily') ?? true,
        morningEnabled: prefs.getBool('morning_enabled') ?? true,
        morningTime: TimeOfDay(hour: prefs.getInt('morning_hour') ?? 9, minute: prefs.getInt('morning_minute') ?? 0),
        afternoonEnabled: prefs.getBool('afternoon_enabled') ?? false,
        afternoonTime: TimeOfDay(
          hour: prefs.getInt('afternoon_hour') ?? 14,
          minute: prefs.getInt('afternoon_minute') ?? 0,
        ),
        eveningEnabled: prefs.getBool('evening_enabled') ?? false,
        eveningTime: TimeOfDay(hour: prefs.getInt('evening_hour') ?? 19, minute: prefs.getInt('evening_minute') ?? 0),
        customReminders: customReminders,
      ),
    );

    // Register the periodic WorkManager task if enabled
    if (state.enabled) {
      await notificationService.requestPermissions();
      await _registerPeriodicTask();
    }
  }

  Future<void> toggleEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_enabled', value);

    // Emit the new state FIRST
    emit(state.copyWith(enabled: value));

    if (value) {
      final granted = await notificationService.requestPermissions();
      if (granted) {
        await _registerPeriodicTask();
        debugPrint('Notification reminders enabled - WorkManager task registered');
      } else {
        debugPrint('Notification permissions not granted');
      }
    } else {
      await _cancelPeriodicTask();
      await notificationService.cancelAllNotifications();
      debugPrint('Notification reminders disabled - WorkManager task cancelled');
    }
  }

  Future<void> toggleRepeatDaily(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('repeat_daily', value);
    emit(state.copyWith(repeatDaily: value));
  }

  Future<void> toggleMorning(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('morning_enabled', value);
    emit(state.copyWith(morningEnabled: value));

    if (!value) {
      await notificationService.cancelNotification(NotificationService.morningNotificationId);
    }
  }

  Future<void> updateMorningTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('morning_hour', time.hour);
    await prefs.setInt('morning_minute', time.minute);
    // Reset the "last fired" tracker so it will fire at the new time
    await prefs.remove('last_morning_notification');
    emit(state.copyWith(morningTime: time));
  }

  Future<void> toggleAfternoon(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('afternoon_enabled', value);
    emit(state.copyWith(afternoonEnabled: value));

    if (!value) {
      await notificationService.cancelNotification(NotificationService.afternoonNotificationId);
    }
  }

  Future<void> updateAfternoonTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('afternoon_hour', time.hour);
    await prefs.setInt('afternoon_minute', time.minute);
    await prefs.remove('last_afternoon_notification');
    emit(state.copyWith(afternoonTime: time));
  }

  Future<void> toggleEvening(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('evening_enabled', value);
    emit(state.copyWith(eveningEnabled: value));

    if (!value) {
      await notificationService.cancelNotification(NotificationService.eveningNotificationId);
    }
  }

  Future<void> updateEveningTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('evening_hour', time.hour);
    await prefs.setInt('evening_minute', time.minute);
    await prefs.remove('last_evening_notification');
    emit(state.copyWith(eveningTime: time));
  }

  // Custom Reminders Logic
  Future<void> addCustomReminder(TimeOfDay time) async {
    final id = state.customReminders.isEmpty
        ? 100
        : state.customReminders.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;

    final reminder = CustomReminder(id: id, time: time);
    final newList = [...state.customReminders, reminder];

    emit(state.copyWith(customReminders: newList));
    await _saveCustomReminders();
  }

  Future<void> toggleCustomReminder(int id, bool value) async {
    final newList = state.customReminders.map((e) {
      if (e.id == id) return e.copyWith(enabled: value);
      return e;
    }).toList();

    emit(state.copyWith(customReminders: newList));
    await _saveCustomReminders();

    if (!value) {
      await notificationService.cancelNotification(id);
    }
  }

  Future<void> updateCustomReminderTime(int id, TimeOfDay time) async {
    final newList = state.customReminders.map((e) {
      if (e.id == id) return e.copyWith(time: time);
      return e;
    }).toList();

    emit(state.copyWith(customReminders: newList));
    await _saveCustomReminders();

    // Reset the "last fired" tracker
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_custom_${id}_notification');
  }

  Future<void> deleteCustomReminder(int id) async {
    final newList = state.customReminders.where((e) => e.id != id).toList();
    emit(state.copyWith(customReminders: newList));
    await _saveCustomReminders();

    await notificationService.cancelNotification(id);
  }

  Future<void> _saveCustomReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(state.customReminders.map((e) => e.toJson()).toList());
    await prefs.setString('custom_reminders', json);
  }

  /// Register a periodic WorkManager task that checks reminders every 15 minutes.
  /// This is the reliable alternative to zonedSchedule which doesn't work on many Android devices.
  Future<void> _registerPeriodicTask() async {
    await Workmanager().registerPeriodicTask(
      'notification_check',
      notificationTaskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.notRequired),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );
    debugPrint('WorkManager periodic notification task registered (every 15 min)');
  }

  /// Cancel the periodic WorkManager task.
  Future<void> _cancelPeriodicTask() async {
    await Workmanager().cancelByUniqueName('notification_check');
    debugPrint('WorkManager periodic notification task cancelled');
  }
}
