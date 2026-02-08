import '../../../../core/services/drive_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UploadToDriveUseCase {
  final DriveService driveService;

  UploadToDriveUseCase(this.driveService);

  Future<bool> call(String jsonContent) async {
    final success = await driveService.uploadBackup(jsonContent);
    if (success) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastBackupTime', DateTime.now().toIso8601String());
    }
    return success;
  }
}
