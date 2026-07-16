import 'package:flutter/foundation.dart';
import 'package:mision_admision/core/time/local_date.dart';
import 'package:mision_admision/domain/models/progress_backup.dart';
import 'package:mision_admision/domain/services/progress_backup_service.dart';
import 'package:mision_admision/platform/backup/backup_file_service.dart';

class BackupSelection {
  const BackupSelection({required this.fileName, required this.backup});

  final String fileName;
  final ProgressBackup backup;
}

class BackupController extends ChangeNotifier {
  BackupController({
    required ProgressBackupService backupService,
    required BackupFileService fileService,
  })  : _backupService = backupService,
        _fileService = fileService;

  final ProgressBackupService _backupService;
  final BackupFileService _fileService;

  bool _busy = false;
  bool get busy => _busy;
  bool get supported => _fileService.supported;

  Future<String> exportBackup() async {
    _setBusy(true);
    try {
      final backup = await _backupService.createBackup();
      final fileName =
          'mision-admision-progreso-${localDateKey(backup.exportedAt)}.json';
      await _fileService.downloadText(
        fileName: fileName,
        content: _backupService.encode(backup),
      );
      return fileName;
    } finally {
      _setBusy(false);
    }
  }

  Future<BackupSelection?> selectBackup() async {
    _setBusy(true);
    try {
      final file = await _fileService.pickJsonFile(
        maximumBytes: ProgressBackupService.maximumBackupBytes,
      );
      if (file == null) return null;
      return BackupSelection(
        fileName: file.name,
        backup: _backupService.decode(file.content),
      );
    } finally {
      _setBusy(false);
    }
  }

  Future<ProgressImportResult> restore(ProgressBackup backup) async {
    _setBusy(true);
    try {
      return await _backupService.restore(backup);
    } finally {
      _setBusy(false);
    }
  }

  Future<void> reset() async {
    _setBusy(true);
    try {
      await _backupService.reset();
    } finally {
      _setBusy(false);
    }
  }

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }
}
