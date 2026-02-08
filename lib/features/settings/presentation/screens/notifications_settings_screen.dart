import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart';
import '../manager/notification_settings_cubit.dart';
import '../manager/notification_settings_state.dart';
import '../../domain/entities/custom_reminder.dart';

class NotificationsSettingsScreen extends StatelessWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<NotificationSettingsCubit>()..loadSettings(),
      child: BlocBuilder<NotificationSettingsCubit, NotificationSettingsState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(title: const Text('Notifications')),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Master Toggles
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Enable Reminders'),
                        subtitle: const Text('Get reminders to practice'),
                        value: state.enabled,
                        onChanged: (value) {
                          context.read<NotificationSettingsCubit>().toggleEnabled(value);
                        },
                        secondary: Icon(
                          state.enabled ? Icons.notifications_active : Icons.notifications_off,
                          color: state.enabled ? Theme.of(context).colorScheme.primary : null,
                        ),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('Daily Schedule'),
                        subtitle: const Text('Work daily at setup times'),
                        value: state.repeatDaily,
                        onChanged: state.enabled
                            ? (value) {
                                context.read<NotificationSettingsCubit>().toggleRepeatDaily(value);
                              }
                            : null,
                        secondary: Icon(
                          Icons.repeat,
                          color: state.enabled && state.repeatDaily ? Theme.of(context).colorScheme.primary : null,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Section Header: Default Reminders
                Opacity(
                  opacity: state.enabled ? 1.0 : 0.5,
                  child: const Text('Reminder Times', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),

                // Morning Reminder
                _buildReminderCard(
                  context: context,
                  title: 'Morning',
                  icon: Icons.wb_sunny,
                  enabled: state.enabled,
                  reminderEnabled: state.morningEnabled,
                  time: state.morningTime,
                  onToggle: (value) {
                    context.read<NotificationSettingsCubit>().toggleMorning(value);
                  },
                  onTimeTap: () async {
                    final time = await showTimePicker(context: context, initialTime: state.morningTime);
                    if (time != null) {
                      context.read<NotificationSettingsCubit>().updateMorningTime(time);
                    }
                  },
                ),

                const SizedBox(height: 12),

                // Afternoon Reminder
                _buildReminderCard(
                  context: context,
                  title: 'Afternoon',
                  icon: Icons.wb_cloudy,
                  enabled: state.enabled,
                  reminderEnabled: state.afternoonEnabled,
                  time: state.afternoonTime,
                  onToggle: (value) {
                    context.read<NotificationSettingsCubit>().toggleAfternoon(value);
                  },
                  onTimeTap: () async {
                    final time = await showTimePicker(context: context, initialTime: state.afternoonTime);
                    if (time != null) {
                      context.read<NotificationSettingsCubit>().updateAfternoonTime(time);
                    }
                  },
                ),

                const SizedBox(height: 12),

                // Evening Reminder
                _buildReminderCard(
                  context: context,
                  title: 'Evening',
                  icon: Icons.nights_stay,
                  enabled: state.enabled,
                  reminderEnabled: state.eveningEnabled,
                  time: state.eveningTime,
                  onToggle: (value) {
                    context.read<NotificationSettingsCubit>().toggleEvening(value);
                  },
                  onTimeTap: () async {
                    final time = await showTimePicker(context: context, initialTime: state.eveningTime);
                    if (time != null) {
                      context.read<NotificationSettingsCubit>().updateEveningTime(time);
                    }
                  },
                ),

                const SizedBox(height: 24),

                // Section Header: Custom Reminders
                Opacity(
                  opacity: state.enabled ? 1.0 : 0.5,
                  child: const Text('Custom Reminders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),

                if (state.customReminders.isEmpty)
                  Opacity(
                    opacity: 0.5,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('No custom reminders added.'),
                    ),
                  ),

                ...state.customReminders.map(
                  (reminder) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildCustomReminderCard(context, state, reminder),
                  ),
                ),

                const SizedBox(height: 80), // Space for FAB
              ],
            ),
            floatingActionButton: state.enabled
                ? FloatingActionButton.extended(
                    onPressed: () async {
                      final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                      if (time != null && context.mounted) {
                        context.read<NotificationSettingsCubit>().addCustomReminder(time);
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Reminder set for ${time.format(context)}')));
                      }
                    },
                    label: const Text('Add Reminder'),
                    icon: const Icon(Icons.add_alarm),
                  )
                : null,
          );
        },
      ),
    );
  }

  Widget _buildReminderCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool enabled,
    required bool reminderEnabled,
    required TimeOfDay time,
    required ValueChanged<bool> onToggle,
    required VoidCallback onTimeTap,
  }) {
    final isActive = enabled && reminderEnabled;

    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Card(
        child: Column(
          children: [
            SwitchListTile(
              title: Text(title),
              subtitle: GestureDetector(
                onTap: enabled ? onTimeTap : null,
                child: Row(
                  children: [
                    Text(
                      time.format(context),
                      style: TextStyle(
                        color: isActive ? Theme.of(context).colorScheme.primary : null,
                        fontWeight: isActive ? FontWeight.bold : null,
                      ),
                    ),
                    if (enabled) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.edit, size: 14, color: Theme.of(context).colorScheme.primary),
                    ],
                  ],
                ),
              ),
              value: reminderEnabled,
              onChanged: enabled ? onToggle : null,
              secondary: Icon(icon, color: isActive ? Theme.of(context).colorScheme.primary : null),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomReminderCard(BuildContext context, NotificationSettingsState state, CustomReminder reminder) {
    final isActive = state.enabled && reminder.enabled;

    return Opacity(
      opacity: state.enabled ? 1.0 : 0.5,
      child: Card(
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Custom Reminder'),
              subtitle: GestureDetector(
                onTap: state.enabled
                    ? () async {
                        final time = await showTimePicker(context: context, initialTime: reminder.time);
                        if (time != null && context.mounted) {
                          context.read<NotificationSettingsCubit>().updateCustomReminderTime(reminder.id, time);
                        }
                      }
                    : null,
                child: Row(
                  children: [
                    Text(
                      reminder.time.format(context),
                      style: TextStyle(
                        color: isActive ? Theme.of(context).colorScheme.primary : null,
                        fontWeight: isActive ? FontWeight.bold : null,
                      ),
                    ),
                    if (state.enabled) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.edit, size: 14, color: Theme.of(context).colorScheme.primary),
                    ],
                  ],
                ),
              ),
              value: reminder.enabled,
              onChanged: state.enabled
                  ? (value) {
                      context.read<NotificationSettingsCubit>().toggleCustomReminder(reminder.id, value);
                    }
                  : null,
              secondary: Icon(Icons.alarm, color: isActive ? Theme.of(context).colorScheme.primary : null),
            ),
            if (state.enabled)
              Padding(
                padding: const EdgeInsets.only(right: 16, bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                      onPressed: () {
                        context.read<NotificationSettingsCubit>().deleteCustomReminder(reminder.id);
                      },
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Remove'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
