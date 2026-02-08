import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class CustomReminder extends Equatable {
  final int id;
  final TimeOfDay time;
  final bool enabled;

  const CustomReminder({required this.id, required this.time, this.enabled = true});

  CustomReminder copyWith({int? id, TimeOfDay? time, bool? enabled}) {
    return CustomReminder(id: id ?? this.id, time: time ?? this.time, enabled: enabled ?? this.enabled);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'hour': time.hour, 'minute': time.minute, 'enabled': enabled};
  }

  factory CustomReminder.fromJson(Map<String, dynamic> json) {
    return CustomReminder(
      id: json['id'] as int,
      time: TimeOfDay(hour: json['hour'] as int, minute: json['minute'] as int),
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [id, time, enabled];
}
