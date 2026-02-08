import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../services/backup_service.dart';
import '../services/drive_service.dart';

const backupTaskName = 'backup_to_drive';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != backupTaskName) return true;

    try {
      // Check if auto-backup is enabled
      final prefs = await SharedPreferences.getInstance();
      final autoBackupEnabled = prefs.getBool('autoBackupEnabled') ?? false;
      if (!autoBackupEnabled) return true;

      // Check time window (4 AM - 6 AM)
      final now = DateTime.now();
      if (now.hour < 4 || now.hour > 6) {
        // Not in backup window, skip
        return true;
      }

      // Initialize services
      final databaseHelper = DatabaseHelper();
      final backupService = BackupService(databaseHelper);
      final driveService = DriveService();

      // Try silent sign-in
      final signedIn = await driveService.signInSilently();
      if (!signedIn) {
        print('Backup worker: Not signed in, skipping backup.');
        return true;
      }

      // Check for changes
      final lastBackupStr = prefs.getString('lastBackupTime');
      final lastBackupTime = lastBackupStr != null ? DateTime.tryParse(lastBackupStr) : null;
      final hasChanges = await backupService.hasChangesSince(lastBackupTime);

      if (!hasChanges) {
        print('Backup worker: No changes since last backup.');
        return true;
      }

      // Perform backup
      final jsonContent = await backupService.exportToJson();
      final success = await driveService.uploadBackup(jsonContent);

      if (success) {
        await prefs.setString('lastBackupTime', DateTime.now().toIso8601String());
        print('Backup worker: Backup completed successfully.');
      } else {
        print('Backup worker: Backup failed.');
      }

      return true;
    } catch (e) {
      print('Backup worker error: $e');
      return false;
    }
  });
}
