import 'dart:convert';

import 'package:mision_admision/domain/models/content_cache_metadata.dart';
import 'package:mision_admision/domain/models/content_file_kind.dart';
import 'package:mision_admision/domain/models/daily_attempt.dart';
import 'package:mision_admision/domain/models/learner_progress.dart';
import 'package:mision_admision/platform/diagnostics/platform_diagnostics_service.dart';
import 'package:mision_admision/platform/notifications/notification_service.dart';
import 'package:mision_admision/platform/pwa/pwa_service.dart';

class SupportDiagnostics {
  const SupportDiagnostics({
    required this.generatedAt,
    required this.appVersion,
    required this.appBuildNumber,
    required this.platform,
    required this.pwa,
    required this.notifications,
    required this.content,
    required this.progress,
    required this.pendingAttempt,
  });

  final DateTime generatedAt;
  final String appVersion;
  final int appBuildNumber;
  final PlatformDiagnostics platform;
  final PwaStatus pwa;
  final NotificationStatus notifications;
  final ContentCacheMetadata content;
  final LearnerProgress progress;
  final DailyAttempt? pendingAttempt;

  Map<String, Object?> toJson() => {
        'schema_version': 1,
        'generated_at': generatedAt.toIso8601String(),
        'application': {
          'name': 'Misión Admisión',
          'version': appVersion,
          'build_number': appBuildNumber,
        },
        'platform': platform.toJson(),
        'pwa': {
          'online': pwa.online,
          'install_mode': pwa.installMode.name,
          'worker_state': pwa.workerState.name,
          'update_available': pwa.updateAvailable,
          'offline_ready': pwa.offlineReady,
          'error_message': pwa.errorMessage,
        },
        'notifications': {
          'configured': notifications.configured,
          'supported': notifications.supported,
          'permission': notifications.permission.name,
          'enabled': notifications.enabled,
          'registration_available': notifications.registrationAvailable,
          'registration_kind': notifications.registrationKind.name,
          'registration_updated_at':
              notifications.registrationUpdatedAt?.toIso8601String(),
          'secure_context': notifications.secureContext,
          'installed_as_pwa': notifications.installedAsPwa,
          'requires_pwa_installation': notifications.requiresPwaInstallation,
          'analytics_configured': notifications.analyticsConfigured,
          'analytics_state': notifications.analyticsState.name,
          'analytics_error_message': notifications.analyticsErrorMessage,
          'error_code': notifications.errorCode,
          'error_message': notifications.errorMessage,
        },
        'content': {
          'content_version': content.contentVersion,
          'last_attempt_at': content.lastAttemptAt?.toIso8601String(),
          'last_success_at': content.lastSuccessAt?.toIso8601String(),
          'last_outcome': content.lastOutcome.name,
          'message': content.message,
          'file_versions': {
            for (final kind in ContentFileKind.values)
              kind.key: content.versionFor(kind),
          },
        },
        'local_progress_summary': {
          'current_streak': progress.currentStreak,
          'best_streak': progress.bestStreak,
          'shields': progress.shields,
          'daily_challenges_completed':
              progress.totalDailyChallengesCompleted,
          'last_completed_date': progress.lastCompletedDateKey,
          'pending_daily_attempt': pendingAttempt != null,
          'pending_attempt_date': pendingAttempt?.dateKey,
          'pending_answer_count': pendingAttempt?.answers.length ?? 0,
        },
        'privacy': {
          'contains_name': false,
          'contains_email': false,
          'contains_question_answers': false,
          'contains_notification_registration': false,
        },
      };

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());

  String toPlainText() {
    final browserVersion = platform.browserVersion.isEmpty
        ? ''
        : ' ${platform.browserVersion}';
    final storage = _storageSummary();
    final lines = <String>[
      'Misión Admisión — diagnóstico técnico',
      'Generado: ${generatedAt.toIso8601String()}',
      'Aplicación: $appVersion+$appBuildNumber',
      'Navegador: ${platform.browserName}$browserVersion',
      'Sistema: ${platform.operatingSystem}',
      'Plataforma: ${platform.platform}',
      'Idioma: ${platform.language}',
      'Zona horaria: ${platform.timeZone}',
      'Pantalla: ${platform.screenWidth}×${platform.screenHeight}',
      'Ventana: ${platform.viewportWidth}×${platform.viewportHeight}',
      'Conexión: ${platform.online ? 'en línea' : 'sin conexión'}',
      'Contexto HTTPS: ${platform.secureContext ? 'sí' : 'no'}',
      'PWA: ${pwa.installMode.name}',
      'Service worker: ${pwa.workerState.name}',
      'Modo offline: ${pwa.offlineReady ? 'preparado' : 'no preparado'}',
      'Actualización disponible: ${pwa.updateAvailable ? 'sí' : 'no'}',
      'Almacenamiento: $storage',
      'Persistente: ${_yesNoUnknown(platform.persistentStorageGranted)}',
      'Notificaciones configuradas: ${notifications.configured ? 'sí' : 'no'}',
      'Notificaciones compatibles: ${notifications.supported ? 'sí' : 'no'}',
      'Permiso de notificación: ${notifications.permission.name}',
      'Notificaciones activadas: ${notifications.enabled ? 'sí' : 'no'}',
      'Registro FCM: ${notifications.registrationKind.name}',
      'Registro actualizado: ${notifications.registrationUpdatedAt?.toIso8601String() ?? 'no disponible'}',
      'PWA requerida para notificar: ${notifications.requiresPwaInstallation ? 'sí' : 'no'}',
      'Google Analytics configurado: ${notifications.analyticsConfigured ? 'sí' : 'no'}',
      'Estado de Analytics: ${notifications.analyticsState.name}',
      'Contenido: ${content.contentVersion ?? 'local inicial'}',
      'Preguntas: ${content.versionFor(ContentFileKind.questions) ?? 'asset'}',
      'Retos: ${content.versionFor(ContentFileKind.challenges) ?? 'asset'}',
      'Recursos: ${content.versionFor(ContentFileKind.resources) ?? 'asset'}',
      'Rangos: ${content.versionFor(ContentFileKind.ranks) ?? 'asset'}',
      'Última sincronización: ${content.lastSuccessAt?.toIso8601String() ?? 'nunca'}',
      'Resultado de sincronización: ${content.lastOutcome.name}',
      'Racha actual: ${progress.currentStreak}',
      'Mejor racha: ${progress.bestStreak}',
      'Escudos: ${progress.shields}',
      'Reto pendiente: ${pendingAttempt == null ? 'no' : 'sí, ${pendingAttempt!.dateKey}'}',
      '',
      'Este reporte no contiene nombre, correo, respuestas ni el registro privado de notificaciones.',
      'La aplicación puede usar Google Analytics para métricas generales y campañas de Firebase.',
    ];
    return lines.join('\n');
  }

  String _storageSummary() {
    final usage = platform.storageUsageBytes;
    final quota = platform.storageQuotaBytes;
    if (usage == null || quota == null) return 'no disponible';
    return '${_formatBytes(usage)} de ${_formatBytes(quota)}';
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kilobytes = bytes / 1024;
    if (kilobytes < 1024) return '${kilobytes.toStringAsFixed(1)} KB';
    final megabytes = kilobytes / 1024;
    if (megabytes < 1024) return '${megabytes.toStringAsFixed(1)} MB';
    final gigabytes = megabytes / 1024;
    return '${gigabytes.toStringAsFixed(1)} GB';
  }

  static String _yesNoUnknown(bool? value) {
    if (value == null) return 'no disponible';
    return value ? 'sí' : 'no';
  }
}
