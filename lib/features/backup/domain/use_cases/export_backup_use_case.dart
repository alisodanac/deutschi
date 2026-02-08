import '../../../../core/services/backup_service.dart';

class ExportBackupUseCase {
  final BackupService backupService;

  ExportBackupUseCase(this.backupService);

  Future<String> call() {
    return backupService.exportToJson();
  }
}
