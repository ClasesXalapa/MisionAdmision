import 'package:mision_admision/core/time/app_clock.dart';
import 'package:mision_admision/domain/models/content_cache_metadata.dart';
import 'package:mision_admision/domain/models/daily_attempt.dart';
import 'package:mision_admision/domain/models/learner_progress.dart';
import 'package:mision_admision/domain/models/support_diagnostics.dart';
import 'package:mision_admision/domain/repositories/content_cache_repository.dart';
import 'package:mision_admision/domain/repositories/daily_attempt_repository.dart';
import 'package:mision_admision/domain/repositories/progress_repository.dart';
import 'package:mision_admision/platform/diagnostics/platform_diagnostics_service.dart';
import 'package:mision_admision/platform/notifications/notification_service.dart';
import 'package:mision_admision/platform/pwa/pwa_service.dart';

class SupportDiagnosticsService {
  const SupportDiagnosticsService({
    required PlatformDiagnosticsService platformService,
    required PwaService pwaService,
    required NotificationService notificationService,
    required ContentCacheRepository contentRepository,
    required ProgressRepository progressRepository,
    required DailyAttemptRepository attemptRepository,
    required AppClock clock,
    required String appVersion,
    required int appBuildNumber,
  })  : _platformService = platformService,
        _pwaService = pwaService,
        _notificationService = notificationService,
        _contentRepository = contentRepository,
        _progressRepository = progressRepository,
        _attemptRepository = attemptRepository,
        _clock = clock,
        _appVersion = appVersion,
        _appBuildNumber = appBuildNumber;

  final PlatformDiagnosticsService _platformService;
  final PwaService _pwaService;
  final NotificationService _notificationService;
  final ContentCacheRepository _contentRepository;
  final ProgressRepository _progressRepository;
  final DailyAttemptRepository _attemptRepository;
  final AppClock _clock;
  final String _appVersion;
  final int _appBuildNumber;

  Future<SupportDiagnostics> collect() async {
    final platform = await _safePlatform();
    final pwa = await _safePwa();
    final notifications = await _safeNotifications();
    final content = await _safeContent();
    final progress = await _safeProgress();
    final attempt = await _safeAttempt();

    return SupportDiagnostics(
      generatedAt: _clock.now(),
      appVersion: _appVersion,
      appBuildNumber: _appBuildNumber,
      platform: platform,
      pwa: pwa,
      notifications: notifications,
      content: content,
      progress: progress,
      pendingAttempt: attempt,
    );
  }

  Future<PlatformDiagnostics> _safePlatform() async {
    try {
      return await _platformService.read();
    } on Object catch (error) {
      return PlatformDiagnostics.unsupported(errorMessage: error.toString());
    }
  }

  Future<PwaStatus> _safePwa() async {
    try {
      return await _pwaService.readStatus();
    } on Object catch (error) {
      return PwaStatus(
        online: true,
        installMode: PwaInstallMode.unavailable,
        workerState: PwaWorkerState.error,
        updateAvailable: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<NotificationStatus> _safeNotifications() async {
    try {
      return await _notificationService.readStatus();
    } on Object catch (error) {
      return NotificationStatus(
        configured: false,
        supported: false,
        permission: NotificationPermissionState.unsupported,
        enabled: false,
        registrationAvailable: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<ContentCacheMetadata> _safeContent() async {
    try {
      return await _contentRepository.loadMetadata();
    } on Object catch (error) {
      return ContentCacheMetadata(
        lastOutcome: ContentSyncOutcome.failed,
        message: error.toString(),
      );
    }
  }

  Future<LearnerProgress> _safeProgress() async {
    try {
      return await _progressRepository.load();
    } on Object {
      return const LearnerProgress();
    }
  }

  Future<DailyAttempt?> _safeAttempt() async {
    try {
      return await _attemptRepository.load();
    } on Object {
      return null;
    }
  }
}
