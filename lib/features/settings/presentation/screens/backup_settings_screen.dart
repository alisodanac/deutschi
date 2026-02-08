import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart';
import '../manager/backup_settings_cubit.dart';
import '../manager/backup_settings_state.dart';

class BackupSettingsScreen extends StatelessWidget {
  const BackupSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<BackupSettingsCubit>()..loadSettings(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Backup & Restore')),
        body: BlocConsumer<BackupSettingsCubit, BackupSettingsState>(
          listener: (context, state) {
            if (state is BackupSettingsLoaded && state.message != null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message!)));
            }
          },
          builder: (context, state) {
            if (state is! BackupSettingsLoaded) {
              return const Center(child: CircularProgressIndicator());
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Google Drive Backup Section
                _buildSectionHeader('Google Drive Backup'),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Connection Status
                        Row(
                          children: [
                            Icon(
                              state.isSignedIn ? Icons.cloud_done : Icons.cloud_off,
                              color: state.isSignedIn ? Colors.green : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              state.isSignedIn ? 'Connected to Google Drive' : 'Not connected',
                              style: TextStyle(color: state.isSignedIn ? Colors.green : Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Connect/Disconnect Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: state.isLoading
                                ? null
                                : () {
                                    if (state.isSignedIn) {
                                      context.read<BackupSettingsCubit>().signOutFromGoogle();
                                    } else {
                                      context.read<BackupSettingsCubit>().signInToGoogle();
                                    }
                                  },
                            icon: Icon(state.isSignedIn ? Icons.logout : Icons.login),
                            label: Text(state.isSignedIn ? 'Disconnect' : 'Connect to Google Drive'),
                          ),
                        ),

                        if (state.isSignedIn) ...[
                          const SizedBox(height: 16),

                          // Last Backup
                          if (state.lastBackupTime != null)
                            Text(
                              'Last backup: ${_formatDateTime(state.lastBackupTime!)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),

                          const SizedBox(height: 8),

                          // Backup Now Button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: state.isLoading ? null : () => context.read<BackupSettingsCubit>().backupNow(),
                              icon: state.isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.backup),
                              label: const Text('Backup Now'),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Restore Button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: state.isLoading
                                  ? null
                                  : () => context.read<BackupSettingsCubit>().restoreFromDrive(),
                              icon: const Icon(Icons.cloud_download),
                              label: const Text('Restore from Drive'),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Auto Backup Toggle
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Auto Backup at 5 AM'),
                            subtitle: const Text('Daily automatic backup'),
                            value: state.autoBackupEnabled,
                            onChanged: (value) {
                              context.read<BackupSettingsCubit>().toggleAutoBackup(value);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Import Section
                _buildSectionHeader('Import Words'),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Import words from a JSON backup file.'),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: state.isLoading
                                ? null
                                : () => context.read<BackupSettingsCubit>().importFromFile(),
                            icon: const Icon(Icons.file_upload),
                            label: const Text('Import from File'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }

  String _formatDateTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoString;
    }
  }
}
