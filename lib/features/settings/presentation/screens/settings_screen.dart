import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme_cubit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Backup Option
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Backup & Restore'),
            subtitle: const Text('Google Drive backup and import'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/backup'),
          ),
          const Divider(),

          // Notifications Option
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            subtitle: const Text('Manage notification preferences'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/notifications'),
          ),
          const Divider(),

          // Theme Option
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Theme'),
            subtitle: BlocBuilder<ThemeCubit, AppThemeMode>(
              builder: (context, mode) {
                return Text(_getThemeName(mode));
              },
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeDialog(context),
          ),
          const Divider(),
        ],
      ),
    );
  }

  String _getThemeName(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
        return 'System default';
    }
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocBuilder<ThemeCubit, AppThemeMode>(
          builder: (context, currentMode) {
            return AlertDialog(
              title: const Text('Choose Theme'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<AppThemeMode>(
                    title: const Text('Light'),
                    value: AppThemeMode.light,
                    groupValue: currentMode,
                    onChanged: (value) {
                      context.read<ThemeCubit>().updateTheme(AppThemeMode.light);
                      Navigator.pop(dialogContext);
                    },
                  ),
                  RadioListTile<AppThemeMode>(
                    title: const Text('Dark'),
                    value: AppThemeMode.dark,
                    groupValue: currentMode,
                    onChanged: (value) {
                      context.read<ThemeCubit>().updateTheme(AppThemeMode.dark);
                      Navigator.pop(dialogContext);
                    },
                  ),
                  RadioListTile<AppThemeMode>(
                    title: const Text('System default'),
                    value: AppThemeMode.system,
                    groupValue: currentMode,
                    onChanged: (value) {
                      context.read<ThemeCubit>().updateTheme(AppThemeMode.system);
                      Navigator.pop(dialogContext);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
