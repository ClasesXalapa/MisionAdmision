import 'package:mision_admision/platform/backup/backup_file_service.dart';
import 'package:mision_admision/platform/backup/backup_file_service_stub.dart'
    if (dart.library.js_interop) 'package:mision_admision/platform/backup/backup_file_service_web.dart'
    as implementation;

BackupFileService createBackupFileService() =>
    implementation.createBackupFileService();
