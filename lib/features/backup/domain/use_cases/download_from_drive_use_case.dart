import '../../../../core/services/drive_service.dart';

class DownloadFromDriveUseCase {
  final DriveService driveService;

  DownloadFromDriveUseCase(this.driveService);

  Future<String?> call() {
    return driveService.downloadBackup();
  }
}
