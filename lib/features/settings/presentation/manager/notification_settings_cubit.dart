import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/notification_service.dart';
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

    // Reschedule if enabled
    if (state.enabled) {
      await _rescheduleAll();
    }
  }

  Future<void> toggleEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_enabled', value);

    if (value) {
      await notificationService.requestPermissions();
      await _rescheduleAll();
    } else {
      await notificationService.cancelAllNotifications();
    }

    emit(state.copyWith(enabled: value));
  }

  Future<void> toggleRepeatDaily(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('repeat_daily', value);

    emit(state.copyWith(repeatDaily: value));

    if (state.enabled) {
      await _rescheduleAll();
    }
  }

  Future<void> toggleMorning(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('morning_enabled', value);

    if (state.enabled) {
      if (value) {
        await _scheduleMorning();
      } else {
        await notificationService.cancelNotification(NotificationService.morningNotificationId);
      }
    }

    emit(state.copyWith(morningEnabled: value));
  }

  Future<void> updateMorningTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('morning_hour', time.hour);
    await prefs.setInt('morning_minute', time.minute);

    emit(state.copyWith(morningTime: time));

    if (state.enabled && state.morningEnabled) {
      await _scheduleMorning();
    }
  }

  Future<void> toggleAfternoon(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('afternoon_enabled', value);

    if (state.enabled) {
      if (value) {
        await _scheduleAfternoon();
      } else {
        await notificationService.cancelNotification(NotificationService.afternoonNotificationId);
      }
    }

    emit(state.copyWith(afternoonEnabled: value));
  }

  Future<void> updateAfternoonTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('afternoon_hour', time.hour);
    await prefs.setInt('afternoon_minute', time.minute);

    emit(state.copyWith(afternoonTime: time));

    if (state.enabled && state.afternoonEnabled) {
      await _scheduleAfternoon();
    }
  }

  Future<void> toggleEvening(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('evening_enabled', value);

    if (state.enabled) {
      if (value) {
        await _scheduleEvening();
      } else {
        await notificationService.cancelNotification(NotificationService.eveningNotificationId);
      }
    }

    emit(state.copyWith(eveningEnabled: value));
  }

  Future<void> updateEveningTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('evening_hour', time.hour);
    await prefs.setInt('evening_minute', time.minute);

    emit(state.copyWith(eveningTime: time));

    if (state.enabled && state.eveningEnabled) {
      await _scheduleEvening();
    }
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

    if (state.enabled && reminder.enabled) {
      await _scheduleCustom(reminder);
    }
  }

  Future<void> toggleCustomReminder(int id, bool value) async {
    final newList = state.customReminders.map((e) {
      if (e.id == id) return e.copyWith(enabled: value);
      return e;
    }).toList();

    emit(state.copyWith(customReminders: newList));
    await _saveCustomReminders();

    if (state.enabled) {
      if (value) {
        final reminder = newList.firstWhere((e) => e.id == id);
        await _scheduleCustom(reminder);
      } else {
        await notificationService.cancelNotification(id);
      }
    }
  }

  Future<void> updateCustomReminderTime(int id, TimeOfDay time) async {
    final newList = state.customReminders.map((e) {
      if (e.id == id) return e.copyWith(time: time);
      return e;
    }).toList();

    emit(state.copyWith(customReminders: newList));
    await _saveCustomReminders();

    final reminder = newList.firstWhere((e) => e.id == id);
    if (state.enabled && reminder.enabled) {
      await _scheduleCustom(reminder);
    }
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

  Future<void> _rescheduleAll() async {
    if (state.morningEnabled) await _scheduleMorning();
    if (state.afternoonEnabled) await _scheduleAfternoon();
    if (state.eveningEnabled) await _scheduleEvening();

    for (final reminder in state.customReminders) {
      if (reminder.enabled) {
        await _scheduleCustom(reminder);
      }
    }
  }

  Future<void> _scheduleMorning() async {
    await notificationService.scheduleDailyNotification(
      id: NotificationService.morningNotificationId,
      title: 'Zeit zum Lernen! 📚',
      body: 'Good morning! Time to practice your German vocabulary.',
      hour: state.morningTime.hour,
      minute: state.morningTime.minute,
      repeatDaily: state.repeatDaily,
    );
  }

  Future<void> _scheduleAfternoon() async {
    await notificationService.scheduleDailyNotification(
      id: NotificationService.afternoonNotificationId,
      title: 'Zeit zum Lernen! 📚',
      body: 'Afternoon break? Perfect time for a quick vocabulary session!',
      hour: state.afternoonTime.hour,
      minute: state.afternoonTime.minute,
      repeatDaily: state.repeatDaily,
    );
  }

  Future<void> _scheduleEvening() async {
    await notificationService.scheduleDailyNotification(
      id: NotificationService.eveningNotificationId,
      title: 'Zeit zum Lernen! 📚',
      body: 'Wind down with some German practice before bed.',
      hour: state.eveningTime.hour,
      minute: state.eveningTime.minute,
      repeatDaily: state.repeatDaily,
    );
  }

  Future<void> _scheduleCustom(CustomReminder reminder) async {
    await notificationService.scheduleDailyNotification(
      id: reminder.id,
      title: 'Zeit zum Lernen! 📚',
      body: 'Time for your custom vocabulary practice session!',
      hour: reminder.time.hour,
      minute: reminder.time.minute,
      repeatDaily: state.repeatDaily,
    );
  }
}
