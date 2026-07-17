import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mision_admision/core/assets/asset_text_loader.dart';
import 'package:mision_admision/core/constants/app_constants.dart';
import 'package:mision_admision/core/network/http_remote_text_client.dart';
import 'package:mision_admision/core/network/remote_text_client.dart';
import 'package:mision_admision/core/storage/json_key_value_store.dart';
import 'package:mision_admision/core/storage/shared_preferences_json_store.dart';
import 'package:mision_admision/core/time/app_clock.dart';
import 'package:mision_admision/data/parsers/content_document_parser.dart';
import 'package:mision_admision/data/parsers/content_index_parser.dart';
import 'package:mision_admision/data/repositories/local_content_cache_repository.dart';
import 'package:mision_admision/data/repositories/local_daily_attempt_repository.dart';
import 'package:mision_admision/data/repositories/local_first_challenge_repository.dart';
import 'package:mision_admision/data/repositories/local_first_question_repository.dart';
import 'package:mision_admision/data/repositories/local_first_rank_repository.dart';
import 'package:mision_admision/data/repositories/local_first_resource_repository.dart';
import 'package:mision_admision/data/repositories/local_progress_repository.dart';
import 'package:mision_admision/data/repositories/local_resource_tracking_repository.dart';
import 'package:mision_admision/data/sources/local_first_content_loader.dart';
import 'package:mision_admision/domain/engines/daily_challenge_engine.dart';
import 'package:mision_admision/domain/engines/exam_engine.dart';
import 'package:mision_admision/domain/engines/rank_engine.dart';
import 'package:mision_admision/domain/engines/streak_engine.dart';
import 'package:mision_admision/domain/repositories/challenge_repository.dart';
import 'package:mision_admision/domain/repositories/content_cache_repository.dart';
import 'package:mision_admision/domain/repositories/daily_attempt_repository.dart';
import 'package:mision_admision/domain/repositories/progress_repository.dart';
import 'package:mision_admision/domain/repositories/question_repository.dart';
import 'package:mision_admision/domain/repositories/rank_repository.dart';
import 'package:mision_admision/domain/repositories/resource_repository.dart';
import 'package:mision_admision/domain/repositories/resource_tracking_repository.dart';
import 'package:mision_admision/domain/services/progress_backup_service.dart';
import 'package:mision_admision/domain/services/support_diagnostics_service.dart';
import 'package:mision_admision/domain/services/content_sync_service.dart';
import 'package:mision_admision/platform/backup/backup_file_service.dart';
import 'package:mision_admision/platform/backup/backup_file_service_factory.dart';
import 'package:mision_admision/platform/diagnostics/platform_diagnostics_service.dart';
import 'package:mision_admision/platform/diagnostics/platform_diagnostics_service_factory.dart';
import 'package:mision_admision/platform/notifications/notification_service.dart';
import 'package:mision_admision/platform/notifications/notification_service_factory.dart';
import 'package:mision_admision/platform/pwa/pwa_service.dart';
import 'package:mision_admision/platform/pwa/pwa_service_factory.dart';

final jsonKeyValueStoreProvider = Provider<JsonKeyValueStore>((ref) {
  return SharedPreferencesJsonStore();
});

final contentCacheRepositoryProvider = Provider<ContentCacheRepository>((ref) {
  return LocalContentCacheRepository(store: ref.read(jsonKeyValueStoreProvider));
});

final assetTextLoaderProvider = Provider<AssetTextLoader>((ref) {
  return const RootBundleAssetTextLoader();
});

final contentDocumentParserProvider = Provider<ContentDocumentParser>((ref) {
  return const ContentDocumentParser();
});

final localFirstContentLoaderProvider = Provider<LocalFirstContentLoader>((ref) {
  return LocalFirstContentLoader(
    cache: ref.read(contentCacheRepositoryProvider),
    assets: ref.read(assetTextLoaderProvider),
  );
});

final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return LocalFirstQuestionRepository(
    loader: ref.read(localFirstContentLoaderProvider),
    parser: ref.read(contentDocumentParserProvider),
    fallbackAssetPath: 'content/preguntas/banco_global.json',
  );
});

final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  return LocalFirstChallengeRepository(
    loader: ref.read(localFirstContentLoaderProvider),
    parser: ref.read(contentDocumentParserProvider),
    fallbackAssetPath: 'content/retos/retos_actuales.json',
  );
});

final rankRepositoryProvider = Provider<RankRepository>((ref) {
  return LocalFirstRankRepository(
    loader: ref.read(localFirstContentLoaderProvider),
    parser: ref.read(contentDocumentParserProvider),
    fallbackAssetPath: 'content/config/rangos.json',
  );
});

final resourceRepositoryProvider = Provider<ResourceRepository>((ref) {
  return LocalFirstResourceRepository(
    loader: ref.read(localFirstContentLoaderProvider),
    parser: ref.read(contentDocumentParserProvider),
    fallbackAssetPath: 'content/cards/cards_actuales.json',
  );
});

final dailyAttemptRepositoryProvider = Provider<DailyAttemptRepository>((ref) {
  return LocalDailyAttemptRepository(store: ref.read(jsonKeyValueStoreProvider));
});

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  return LocalProgressRepository(
    store: ref.read(jsonKeyValueStoreProvider),
    onProgressChanged: (progress) async {
      await ref.read(notificationServiceProvider).syncDailyChallengeState(
            lastCompletedDateKey: progress.lastCompletedDateKey,
            challengeAvailable: true,
          );
    },
  );
});

final resourceTrackingRepositoryProvider =
    Provider<ResourceTrackingRepository>((ref) {
  return LocalResourceTrackingRepository(
    store: ref.read(jsonKeyValueStoreProvider),
  );
});

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final remoteTextClientProvider = Provider<RemoteTextClient>((ref) {
  return HttpRemoteTextClient(client: ref.read(httpClientProvider));
});

final contentIndexParserProvider = Provider<ContentIndexParser>((ref) {
  return const ContentIndexParser();
});

final contentSyncServiceProvider = Provider<ContentSyncService>((ref) {
  return ContentSyncService(
    remoteClient: ref.read(remoteTextClientProvider),
    cache: ref.read(contentCacheRepositoryProvider),
    attemptRepository: ref.read(dailyAttemptRepositoryProvider),
    localLoader: ref.read(localFirstContentLoaderProvider),
    indexParser: ref.read(contentIndexParserProvider),
    documentParser: ref.read(contentDocumentParserProvider),
    clock: ref.read(appClockProvider),
    baseUri: Uri.base,
    appBuildNumber: AppConstants.appBuildNumber,
  );
});

final examEngineProvider = Provider<ExamEngine>((ref) {
  return const ExamEngine();
});

final dailyChallengeEngineProvider = Provider<DailyChallengeEngine>((ref) {
  return const DailyChallengeEngine();
});

final streakEngineProvider = Provider<StreakEngine>((ref) {
  return const StreakEngine();
});

final rankEngineProvider = Provider<RankEngine>((ref) {
  return const RankEngine();
});

final appClockProvider = Provider<AppClock>((ref) {
  return const SystemAppClock();
});

final pwaServiceProvider = Provider<PwaService>((ref) {
  return createPwaService();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return createNotificationService();
});

final backupFileServiceProvider = Provider<BackupFileService>((ref) {
  return createBackupFileService();
});

final progressBackupServiceProvider = Provider<ProgressBackupService>((ref) {
  return ProgressBackupService(
    progressRepository: ref.read(progressRepositoryProvider),
    attemptRepository: ref.read(dailyAttemptRepositoryProvider),
    trackingRepository: ref.read(resourceTrackingRepositoryProvider),
    clock: ref.read(appClockProvider),
    appVersion: AppConstants.appVersion,
  );
});

final platformDiagnosticsServiceProvider =
    Provider<PlatformDiagnosticsService>((ref) {
  return createPlatformDiagnosticsService();
});

final supportDiagnosticsServiceProvider = Provider<SupportDiagnosticsService>((ref) {
  return SupportDiagnosticsService(
    platformService: ref.read(platformDiagnosticsServiceProvider),
    pwaService: ref.read(pwaServiceProvider),
    notificationService: ref.read(notificationServiceProvider),
    contentRepository: ref.read(contentCacheRepositoryProvider),
    progressRepository: ref.read(progressRepositoryProvider),
    attemptRepository: ref.read(dailyAttemptRepositoryProvider),
    clock: ref.read(appClockProvider),
    appVersion: AppConstants.appVersion,
    appBuildNumber: AppConstants.appBuildNumber,
  );
});
