import '../../../../core/services/backup_service.dart';

class ImportBackupUseCase {
  final BackupService backupService;

  ImportBackupUseCase(this.backupService);

  Future<int> call(String jsonContent) {
    return backupService.importFromJson(jsonContent);
  }
}
