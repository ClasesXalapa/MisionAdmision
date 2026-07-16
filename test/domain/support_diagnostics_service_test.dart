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
import 'package:mision_admision/platform/diagnostics/platform_diagnostics_service.dart';
import 'package:mision_admision/platform/notifications/notification_service.dart';
import 'package:mision_admision/platform/pwa/pwa_service.dart';

void main() {
  test('collects a privacy-safe support report', () async {
    final service = SupportDiagnosticsService(
      platformService: const _PlatformService(),
      pwaService: const _PwaService(),
      notificationService: const _NotificationService(),
      contentRepository: _ContentRepository(),
      progressRepository: const _ProgressRepository(),
      attemptRepository: const _AttemptRepository(),
      clock: const _Clock(),
      appVersion: '0.8.1',
      appBuildNumber: 11,
    );

    final report = await service.collect();
    final json = report.toJson();
    final privacy = json['privacy']! as Map<String, Object?>;
    final progress = json['local_progress_summary']! as Map<String, Object?>;

    expect(report.appVersion, '0.8.1');
    expect(report.platform.browserName, 'Chrome');
    expect(report.content.contentVersion, 'content_002');
    expect(report.progress.currentStreak, 4);
    expect(progress['pending_answer_count'], 0);
    expect(privacy['contains_question_answers'], isFalse);
    expect(report.toPlainText(), contains('Misión Admisión'));
    expect(report.toPrettyJson(), isNot(contains('respuesta_correcta')));
  });
}

class _PlatformService implements PlatformDiagnosticsService {
  const _PlatformService();

  @override
  Future<PlatformDiagnostics> read() async {
    return const PlatformDiagnostics(
      supported: true,
      browserName: 'Chrome',
      browserVersion: '150',
      operatingSystem: 'Android 16',
      platform: 'Android',
      userAgent: 'agent',
      language: 'es-MX',
      timeZone: 'America/Mexico_City',
      screenWidth: 390,
      screenHeight: 844,
      viewportWidth: 390,
      viewportHeight: 700,
      devicePixelRatio: 3,
      online: true,
      secureContext: true,
      cookiesEnabled: true,
      displayMode: 'standalone',
      serviceWorkerSupported: true,
      serviceWorkerControlled: true,
      serviceWorkerState: 'activated',
      storageEstimateSupported: true,
      storageUsageBytes: 1024,
      storageQuotaBytes: 4096,
      persistentStorageSupported: true,
      persistentStorageGranted: true,
      connectionType: '4g',
    );
  }
}

class _PwaService implements PwaService {
  const _PwaService();

  @override
  Future<bool> activateUpdate() async => false;

  @override
  Future<PwaStatus> readStatus() async {
    return const PwaStatus(
      online: true,
      installMode: PwaInstallMode.installed,
      workerState: PwaWorkerState.active,
      updateAvailable: false,
    );
  }

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
  Future<NotificationStatus> readStatus() async {
    return const NotificationStatus(
      configured: false,
      supported: false,
      permission: NotificationPermissionState.defaultState,
      enabled: false,
      registrationAvailable: false,
    );
  }

  @override
  Future<NotificationStatus> refreshRegistration() => readStatus();

  @override
  Future<bool> showLocalTest() async => false;

  @override
  Future<String?> getTestingInstallationId() async => null;
}

class _ContentRepository implements ContentCacheRepository {
  final metadata = ContentCacheMetadata(
    contentVersion: 'content_002',
    lastOutcome: ContentSyncOutcome.success,
    fileVersions: const {
      ContentFileKind.questions: 'questions_002',
      ContentFileKind.challenges: 'challenges_002',
    },
  );

  @override
  Future<void> discard(ContentFileKind kind) async {}

  @override
  Future<void> discardVersion(ContentFileKind kind, String version) async {}

  @override
  Future<ContentCacheMetadata> loadMetadata() async => metadata;

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
  Future<LearnerProgress> load() async {
    return const LearnerProgress(
      currentStreak: 4,
      bestStreak: 7,
      shields: 1,
      totalDailyChallengesCompleted: 8,
    );
  }

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
  DateTime now() => DateTime.parse('2026-07-16T12:00:00-06:00');
}
