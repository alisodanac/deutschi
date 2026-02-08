import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/custom_reminder.dart';

class NotificationSettingsState extends Equatable {
  final bool enabled;
  final bool repeatDaily;
  final bool morningEnabled;
  final TimeOfDay morningTime;
  final bool afternoonEnabled;
  final TimeOfDay afternoonTime;
  final bool eveningEnabled;
  final TimeOfDay eveningTime;
  final List<CustomReminder> customReminders;

  const NotificationSettingsState({
    this.enabled = false,
    this.repeatDaily = true,
    this.morningEnabled = true,
    this.morningTime = const TimeOfDay(hour: 9, minute: 0),
    this.afternoonEnabled = false,
    this.afternoonTime = const TimeOfDay(hour: 14, minute: 0),
    this.eveningEnabled = false,
    this.eveningTime = const TimeOfDay(hour: 19, minute: 0),
    this.customReminders = const [],
  });

  NotificationSettingsState copyWith({
    bool? enabled,
    bool? repeatDaily,
    bool? morningEnabled,
    TimeOfDay? morningTime,
    bool? afternoonEnabled,
    TimeOfDay? afternoonTime,
    bool? eveningEnabled,
    TimeOfDay? eveningTime,
    List<CustomReminder>? customReminders,
  }) {
    return NotificationSettingsState(
      enabled: enabled ?? this.enabled,
      repeatDaily: repeatDaily ?? this.repeatDaily,
      morningEnabled: morningEnabled ?? this.morningEnabled,
      morningTime: morningTime ?? this.morningTime,
      afternoonEnabled: afternoonEnabled ?? this.afternoonEnabled,
      afternoonTime: afternoonTime ?? this.afternoonTime,
      eveningEnabled: eveningEnabled ?? this.eveningEnabled,
      eveningTime: eveningTime ?? this.eveningTime,
      customReminders: customReminders ?? this.customReminders,
    );
  }

  @override
  List<Object?> get props => [
    enabled,
    repeatDaily,
    morningEnabled,
    morningTime,
    afternoonEnabled,
    afternoonTime,
    eveningEnabled,
    eveningTime,
    customReminders,
  ];
}
