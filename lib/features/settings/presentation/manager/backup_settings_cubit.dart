import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:workmanager/workmanager.dart';
import '../../../../core/services/backup_service.dart';
import '../../../../core/services/drive_service.dart';
import 'backup_settings_state.dart';

class BackupSettingsCubit extends Cubit<BackupSettingsState> {
  final BackupService backupService;
  final DriveService driveService;

  BackupSettingsCubit(this.backupService, this.driveService) : super(BackupSettingsInitial());

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final lastBackup = prefs.getString('lastBackupTime');
    final autoBackup = prefs.getBool('autoBackupEnabled') ?? false;

    // Try to sign in silently to restore connection
    final isSignedIn = await driveService.signInSilently();

    emit(BackupSettingsLoaded(isSignedIn: isSignedIn, lastBackupTime: lastBackup, autoBackupEnabled: autoBackup));
  }

  Future<void> signInToGoogle() async {
    if (state is! BackupSettingsLoaded) return;
    final currentState = state as BackupSettingsLoaded;

    emit(currentState.copyWith(isLoading: true, message: null));

    final success = await driveService.signIn();

    emit(
      currentState.copyWith(
        isLoading: false,
        isSignedIn: success,
        message: success ? 'Connected to Google Drive!' : 'Failed to connect.',
      ),
    );
  }

  Future<void> signOutFromGoogle() async {
    if (state is! BackupSettingsLoaded) return;
    final currentState = state as BackupSettingsLoaded;

    await driveService.signOut();

    emit(currentState.copyWith(isSignedIn: false, message: 'Disconnected from Google Drive.'));
  }

  Future<void> backupNow() async {
    if (state is! BackupSettingsLoaded) return;
    final currentState = state as BackupSettingsLoaded;

    emit(currentState.copyWith(isLoading: true, message: 'Creating backup...'));

    try {
      final jsonContent = await backupService.exportToJson();
      final success = await driveService.uploadBackup(jsonContent);

      if (success) {
        final prefs = await SharedPreferences.getInstance();
        final now = DateTime.now().toIso8601String();
        await prefs.setString('lastBackupTime', now);

        emit(currentState.copyWith(isLoading: false, lastBackupTime: now, message: 'Backup completed successfully!'));
      } else {
        emit(currentState.copyWith(isLoading: false, message: 'Backup failed. Please try again.'));
      }
    } catch (e) {
      emit(currentState.copyWith(isLoading: false, message: 'Error: $e'));
    }
  }

  Future<void> toggleAutoBackup(bool enabled) async {
    if (state is! BackupSettingsLoaded) return;
    final currentState = state as BackupSettingsLoaded;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoBackupEnabled', enabled);

    if (enabled) {
      await Workmanager().registerPeriodicTask(
        'deutschi_backup_task',
        'backup_to_drive',
        frequency: const Duration(hours: 24),
        constraints: Constraints(networkType: NetworkType.connected),
      );
    } else {
      await Workmanager().cancelByUniqueName('deutschi_backup_task');
    }

    emit(currentState.copyWith(autoBackupEnabled: enabled));
  }

  Future<void> importFromFile() async {
    if (state is! BackupSettingsLoaded) return;
    final currentState = state as BackupSettingsLoaded;

    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);

      if (result == null || result.files.isEmpty) return;

      emit(currentState.copyWith(isLoading: true, message: 'Importing...'));

      final file = File(result.files.single.path!);
      final jsonContent = await file.readAsString();
      final importedCount = await backupService.importFromJson(jsonContent);

      emit(currentState.copyWith(isLoading: false, message: 'Imported $importedCount new words!'));
    } catch (e) {
      emit(currentState.copyWith(isLoading: false, message: 'Import failed: $e'));
    }
  }

  Future<void> restoreFromDrive() async {
    if (state is! BackupSettingsLoaded) return;
    final currentState = state as BackupSettingsLoaded;

    emit(currentState.copyWith(isLoading: true, message: 'Downloading backup...'));

    try {
      final jsonContent = await driveService.downloadBackup();
      if (jsonContent == null) {
        emit(currentState.copyWith(isLoading: false, message: 'No backup found on Drive.'));
        return;
      }

      final importedCount = await backupService.importFromJson(jsonContent);

      emit(currentState.copyWith(isLoading: false, message: 'Restored $importedCount new words from Drive!'));
    } catch (e) {
      emit(currentState.copyWith(isLoading: false, message: 'Restore failed: $e'));
    }
  }
}
