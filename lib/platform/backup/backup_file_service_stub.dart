import 'package:mision_admision/platform/backup/backup_file_service.dart';

BackupFileService createBackupFileService() =>
    const UnsupportedBackupFileService();

class UnsupportedBackupFileService implements BackupFileService {
  const UnsupportedBackupFileService();

  @override
  bool get supported => false;

  @override
  Future<void> downloadText({
    required String fileName,
    required String content,
  }) {
    throw UnsupportedError('La descarga no está disponible en esta plataforma.');
  }

  @override
  Future<PickedBackupFile?> pickJsonFile({required int maximumBytes}) {
    throw UnsupportedError('La importación no está disponible en esta plataforma.');
  }
}
