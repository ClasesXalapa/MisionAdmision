import 'package:flutter_test/flutter_test.dart';
import 'package:mision_admision/core/time/app_clock.dart';
import 'package:mision_admision/domain/models/content_cache_metadata.dart';
import 'package:mision_admision/domain/models/content_file_kind.dart';
import 'package:mision_admision/domain/models/daily_attempt.dart';
import 'package:mision_admision/domain/models/learner_progress.dart';
import 'package:mision_admision/domain/repositories/content_cache_repository.dart';
import 'package:mision_admision/domain/repositories/daily_attempt_repository.dart';
import 'package:mision_admision/domain/repositories/progress_repository.dart';
import 'package:mision_admision/domain/services/support_diagnostics_service.dart';
import 'package:mision_admision/features/support/application/diagnostics_controller.dart';
import 'package:mision_admision/platform/backup/backup_file_service.dart';
import 'package:mision_admision/platform/diagnostics/platform_diagnostics_service.dart';
import 'package:mision_admision/platform/notifications/notification_service.dart';
import 'package:mision_admision/platform/pwa/pwa_service.dart';

void main() {
  test('loads and downloads the diagnostics report', () async {
    final fileService = _FileService();
    final controller = DiagnosticsController(
      diagnosticsService: SupportDiagnosticsService(
        platformService: const _PlatformService(),
        pwaService: const _PwaService(),
        notificationService: const _NotificationService(),
        contentRepository: const _ContentRepository(),
        progressRepository: const _ProgressRepository(),
        attemptRepository: const _AttemptRepository(),
        clock: const _Clock(),
        appVersion: '0.8.1',
        appBuildNumber: 11,
      ),
      fileService: fileService,
    );
    addTearDown(controller.dispose);

    await controller.start();
    expect(controller.loading, isFalse);
    expect(controller.report, isNotNull);

    expect(await controller.downloadReport(), isTrue);
    expect(fileService.fileName, contains('diagnostico-2026-07-16'));
    expect(fileService.content, contains('"schema_version": 1'));
  });
}

class _FileService implements BackupFileService {
  String? fileName;
  String? content;

  @override
  bool get supported => true;

  @override
  Future<void> downloadText({
    required String fileName,
    required String content,
  }) async {
    this.fileName = fileName;
    this.content = content;
  }

  @override
  Future<PickedBackupFile?> pickJsonFile({required int maximumBytes}) async =>
      null;
}

class _PlatformService implements PlatformDiagnosticsService {
  const _PlatformService();

  @override
  Future<PlatformDiagnostics> read() async =>
      const PlatformDiagnostics.unsupported();
}

class _PwaService implements PwaService {
  const _PwaService();

  @override
  Future<bool> activateUpdate() async => false;

  @override
  Future<PwaStatus> readStatus() async => const PwaStatus.unsupported();

  @override
  Future<bool> requestInstall() async => false;
}

class _NotificationService implements NotificationService {
  const _NotificationService();

  @override
  Future<NotificationStatus> disable() => readStatus();

  @override
  Future<NotificationStatus> enable() => readStatus();

  @override
  Future<NotificationStatus> readStatus() async =>
      const NotificationStatus.unsupported();

  @override
  Future<NotificationStatus> refreshRegistration() => readStatus();

  @override
  Future<bool> showLocalTest() async => false;
}

class _ContentRepository implements ContentCacheRepository {
  const _ContentRepository();

  @override
  Future<void> discard(ContentFileKind kind) async {}

  @override
  Future<void> discardVersion(ContentFileKind kind, String version) async {}

  @override
  Future<ContentCacheMetadata> loadMetadata() async => ContentCacheMetadata();

  @override
  Future<String?> readRaw(ContentFileKind kind) async => null;

  @override
  Future<void> saveMetadata(ContentCacheMetadata metadata) async {}

  @override
  Future<void> writeRaw(
    ContentFileKind kind,
    String version,
    String raw,
  ) async {}
}

class _ProgressRepository implements ProgressRepository {
  const _ProgressRepository();

  @override
  Future<LearnerProgress> load() async => const LearnerProgress();

  @override
  Future<void> save(LearnerProgress progress) async {}
}

class _AttemptRepository implements DailyAttemptRepository {
  const _AttemptRepository();

  @override
  Future<void> clear() async {}

  @override
  Future<DailyAttempt?> load() async => null;

  @override
  Future<void> save(DailyAttempt attempt) async {}
}

class _Clock implements AppClock {
  const _Clock();

  @override
  DateTime now() => DateTime.parse('2026-07-16T08:00:00-06:00');
}
