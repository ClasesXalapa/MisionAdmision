import 'dart:convert';

import 'package:mision_admision/core/time/app_clock.dart';
import 'package:mision_admision/core/time/local_date.dart';
import 'package:mision_admision/data/dto/daily_attempt_dto.dart';
import 'package:mision_admision/data/dto/learner_progress_dto.dart';
import 'package:mision_admision/data/dto/resource_tracking_dto.dart';
import 'package:mision_admision/domain/models/daily_attempt.dart';
import 'package:mision_admision/domain/models/learner_progress.dart';
import 'package:mision_admision/domain/models/progress_backup.dart';
import 'package:mision_admision/domain/models/resource_tracking.dart';
import 'package:mision_admision/domain/repositories/daily_attempt_repository.dart';
import 'package:mision_admision/domain/repositories/progress_repository.dart';
import 'package:mision_admision/domain/repositories/resource_tracking_repository.dart';

class ProgressBackupService {
  ProgressBackupService({
    required ProgressRepository progressRepository,
    required DailyAttemptRepository attemptRepository,
    required ResourceTrackingRepository trackingRepository,
    required AppClock clock,
    required String appVersion,
  })  : _progressRepository = progressRepository,
        _attemptRepository = attemptRepository,
        _trackingRepository = trackingRepository,
        _clock = clock,
        _appVersion = appVersion;

  static const String format = 'mision_admision_progress_backup';
  static const int schemaVersion = 1;
  static const int maximumBackupBytes = 512 * 1024;
  static const int maximumTrackedResources = 10000;
  static const int maximumResourceIdLength = 200;
  static const int maximumAttemptQuestions = 100;

  final ProgressRepository _progressRepository;
  final DailyAttemptRepository _attemptRepository;
  final ResourceTrackingRepository _trackingRepository;
  final AppClock _clock;
  final String _appVersion;

  Future<ProgressBackup> createBackup() async {
    final values = await Future.wait<Object?>([
      _progressRepository.load(),
      _attemptRepository.load(),
      _trackingRepository.load(),
    ]);
    return ProgressBackup(
      exportedAt: _clock.now(),
      appVersion: _appVersion,
      progress: values[0] as LearnerProgress,
      dailyAttempt: values[1] as DailyAttempt?,
      tracking: values[2] as ResourceTracking,
    );
  }

  String encode(ProgressBackup backup) {
    final document = <String, Object?>{
      'format': format,
      'schema_version': schemaVersion,
      'app_version': backup.appVersion,
      'exported_at': backup.exportedAt.toIso8601String(),
      'data': {
        'learner_progress':
            LearnerProgressDto.fromDomain(backup.progress).toJson(),
        'daily_attempt': backup.dailyAttempt == null
            ? null
            : DailyAttemptDto.fromDomain(backup.dailyAttempt!).toJson(),
        'resource_tracking':
            ResourceTrackingDto.fromDomain(backup.tracking).toJson(),
      },
    };
    return const JsonEncoder.withIndent('  ').convert(document);
  }

  ProgressBackup decode(String raw) {
    if (utf8.encode(raw).length > maximumBackupBytes) {
      throw const FormatException('El archivo de respaldo supera 512 KB.');
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('El respaldo debe contener un objeto JSON.');
    }
    if (decoded['format'] != format) {
      throw const FormatException('El archivo no es un respaldo de Misión Admisión.');
    }
    if (decoded['schema_version'] != schemaVersion) {
      throw const FormatException('La versión del respaldo no es compatible.');
    }

    final appVersion = decoded['app_version'];
    final exportedAtRaw = decoded['exported_at'];
    final data = decoded['data'];
    if (appVersion is! String ||
        appVersion.trim().isEmpty ||
        appVersion.length > 50) {
      throw const FormatException('El respaldo no declara una versión válida.');
    }
    if (exportedAtRaw is! String) {
      throw const FormatException('El respaldo no declara su fecha de exportación.');
    }
    final exportedAt = DateTime.tryParse(exportedAtRaw);
    if (exportedAt == null) {
      throw const FormatException('La fecha de exportación no es válida.');
    }
    if (exportedAt.isAfter(_clock.now().add(const Duration(days: 1)))) {
      throw const FormatException('El respaldo declara una fecha futura inválida.');
    }
    if (data is! Map<String, dynamic>) {
      throw const FormatException('El respaldo no contiene datos válidos.');
    }

    final progressJson = _requiredObject(data, 'learner_progress');
    final trackingJson = _requiredObject(data, 'resource_tracking');
    final progress = LearnerProgressDto.fromJson(progressJson).toDomain();
    _validateProgressDates(progress);
    _validateTrackingJson(trackingJson);
    final tracking = ResourceTrackingDto.fromJson(trackingJson).toDomain();

    DailyAttempt? attempt;
    final attemptJson = data['daily_attempt'];
    if (attemptJson != null) {
      if (attemptJson is! Map<String, dynamic>) {
        throw const FormatException('El intento diario del respaldo es inválido.');
      }
      attempt = DailyAttemptDto.fromJson(attemptJson).toDomain();
      if (attempt.questionIds.length > maximumAttemptQuestions) {
        throw const FormatException('El intento diario contiene demasiadas preguntas.');
      }
    }

    return ProgressBackup(
      exportedAt: exportedAt,
      appVersion: appVersion.trim(),
      progress: progress,
      tracking: tracking,
      dailyAttempt: attempt,
    );
  }

  Future<ProgressImportResult> restore(ProgressBackup backup) async {
    final previousProgress = await _progressRepository.load();
    final previousAttempt = await _attemptRepository.load();
    final previousTracking = await _trackingRepository.load();

    final todayKey = localDateKey(_clock.now());
    final importedAttempt = backup.dailyAttempt;
    final attemptDate = importedAttempt == null
        ? null
        : parseLocalDateKey(importedAttempt.dateKey);
    final today = parseLocalDateKey(todayKey);
    if (attemptDate != null && attemptDate.isAfter(today)) {
      throw const FormatException('El respaldo contiene un reto pendiente futuro.');
    }
    final shouldRestoreAttempt = importedAttempt?.dateKey == todayKey;
    final staleAttemptDiscarded = importedAttempt != null && !shouldRestoreAttempt;

    try {
      await _progressRepository.save(backup.progress);
      await _trackingRepository.save(backup.tracking);
      if (shouldRestoreAttempt) {
        await _attemptRepository.save(importedAttempt!);
      } else {
        await _attemptRepository.clear();
      }
    } on Object {
      await _restorePrevious(
        progress: previousProgress,
        attempt: previousAttempt,
        tracking: previousTracking,
      );
      rethrow;
    }

    return ProgressImportResult(
      progress: backup.progress,
      tracking: backup.tracking,
      attemptRestored: shouldRestoreAttempt,
      staleAttemptDiscarded: staleAttemptDiscarded,
    );
  }

  Future<void> reset() async {
    final previousProgress = await _progressRepository.load();
    final previousAttempt = await _attemptRepository.load();
    final previousTracking = await _trackingRepository.load();
    try {
      await _progressRepository.save(const LearnerProgress());
      await _trackingRepository.save(ResourceTracking());
      await _attemptRepository.clear();
    } on Object {
      await _restorePrevious(
        progress: previousProgress,
        attempt: previousAttempt,
        tracking: previousTracking,
      );
      rethrow;
    }
  }

  Map<String, dynamic> _requiredObject(
    Map<String, dynamic> parent,
    String key,
  ) {
    final value = parent[key];
    if (value is! Map<String, dynamic>) {
      throw FormatException('El respaldo no contiene $key de forma válida.');
    }
    return value;
  }

  void _validateProgressDates(LearnerProgress progress) {
    if (progress.totalDailyChallengesCompleted < progress.currentStreak ||
        progress.totalDailyChallengesCompleted < progress.bestStreak ||
        progress.lastShieldUseCount > LearnerProgress.maximumShields ||
        (progress.lastShieldUseCount > 0 &&
            progress.lastShieldUsedDateKey == null)) {
      throw const FormatException(
        'El respaldo contiene una combinación de progreso inválida.',
      );
    }
    final today = parseLocalDateKey(localDateKey(_clock.now()));
    for (final value in [
      progress.lastCompletedDateKey,
      progress.lastStreakDateKey,
      progress.lastShieldUsedDateKey,
    ]) {
      if (value != null && parseLocalDateKey(value).isAfter(today)) {
        throw const FormatException('El progreso contiene una fecha futura inválida.');
      }
    }
  }

  void _validateTrackingJson(Map<String, dynamic> json) {
    final viewed = _strictStringList(json['viewed_ids'], 'viewed_ids');
    final completed = _strictStringList(json['completed_ids'], 'completed_ids');
    if (viewed.length > maximumTrackedResources ||
        completed.length > maximumTrackedResources) {
      throw const FormatException('El respaldo contiene demasiados recursos.');
    }
    if (!viewed.toSet().containsAll(completed)) {
      throw const FormatException(
        'Los recursos completados también deben estar marcados como vistos.',
      );
    }
    for (final id in {...viewed, ...completed}) {
      if (id.length > maximumResourceIdLength) {
        throw const FormatException('El respaldo contiene un ID demasiado largo.');
      }
    }
  }

  List<String> _strictStringList(Object? value, String label) {
    if (value is! List || value.any((item) => item is! String)) {
      throw FormatException('$label debe ser una lista de texto.');
    }
    final result = value.cast<String>();
    if (result.any((item) => item.trim().isEmpty)) {
      throw FormatException('$label contiene IDs vacíos.');
    }
    if (result.toSet().length != result.length) {
      throw FormatException('$label contiene IDs duplicados.');
    }
    return result;
  }

  Future<void> _restorePrevious({
    required LearnerProgress progress,
    required DailyAttempt? attempt,
    required ResourceTracking tracking,
  }) async {
    try {
      await _progressRepository.save(progress);
      await _trackingRepository.save(tracking);
      if (attempt == null) {
        await _attemptRepository.clear();
      } else {
        await _attemptRepository.save(attempt);
      }
    } on Object {
      // Se conserva el error original. El almacenamiento local puede haber sido
      // bloqueado por el navegador y no siempre permite completar el rollback.
    }
  }
}
