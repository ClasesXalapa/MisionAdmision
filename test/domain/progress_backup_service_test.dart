import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mision_admision/core/time/app_clock.dart';
import 'package:mision_admision/data/repositories/local_daily_attempt_repository.dart';
import 'package:mision_admision/data/repositories/local_progress_repository.dart';
import 'package:mision_admision/data/repositories/local_resource_tracking_repository.dart';
import 'package:mision_admision/domain/models/answer_option.dart';
import 'package:mision_admision/domain/models/daily_attempt.dart';
import 'package:mision_admision/domain/models/exam_kind.dart';
import 'package:mision_admision/domain/models/learner_progress.dart';
import 'package:mision_admision/domain/models/resource_tracking.dart';
import 'package:mision_admision/domain/services/progress_backup_service.dart';

import '../helpers/memory_json_store.dart';

void main() {
  late MemoryJsonStore store;
  late LocalProgressRepository progressRepository;
  late LocalDailyAttemptRepository attemptRepository;
  late LocalResourceTrackingRepository trackingRepository;
  late ProgressBackupService service;

  setUp(() {
    store = MemoryJsonStore();
    progressRepository = LocalProgressRepository(store: store);
    attemptRepository = LocalDailyAttemptRepository(store: store);
    trackingRepository = LocalResourceTrackingRepository(store: store);
    service = ProgressBackupService(
      progressRepository: progressRepository,
      attemptRepository: attemptRepository,
      trackingRepository: trackingRepository,
      clock: _FixedClock(DateTime(2026, 7, 16, 12)),
      appVersion: '0.7.0',
    );
  });

  test('crea, codifica y decodifica un respaldo completo', () async {
    const progress = LearnerProgress(
      currentStreak: 4,
      bestStreak: 8,
      shields: 1,
      lastCompletedDateKey: '2026-07-16',
      lastStreakDateKey: '2026-07-16',
      totalDailyChallengesCompleted: 12,
    );
    final tracking = ResourceTracking(
      viewedIds: {'card_1', 'card_2'},
      completedIds: {'card_1'},
    );
    final attempt = _attempt('2026-07-16');
    await progressRepository.save(progress);
    await trackingRepository.save(tracking);
    await attemptRepository.save(attempt);

    final backup = await service.createBackup();
    final decoded = service.decode(service.encode(backup));

    expect(decoded.progress.currentStreak, 4);
    expect(decoded.progress.bestStreak, 8);
    expect(decoded.tracking.completedIds, {'card_1'});
    expect(decoded.dailyAttempt?.challengeId, 'reto_1');
  });

  test('rechaza un documento con formato desconocido', () {
    final raw = jsonEncode({
      'format': 'otro_formato',
      'schema_version': 1,
    });

    expect(() => service.decode(raw), throwsFormatException);
  });

  test('restaura el intento pendiente de la fecha actual', () async {
    final backup = service.decode(_backupJson(attemptDate: '2026-07-16'));

    final result = await service.restore(backup);

    expect(result.attemptRestored, isTrue);
    expect(result.staleAttemptDiscarded, isFalse);
    expect((await attemptRepository.load())?.dateKey, '2026-07-16');
    expect((await progressRepository.load()).currentStreak, 3);
  });

  test('descarta un intento vencido y conserva el resto del progreso', () async {
    final backup = service.decode(_backupJson(attemptDate: '2026-07-15'));

    final result = await service.restore(backup);

    expect(result.attemptRestored, isFalse);
    expect(result.staleAttemptDiscarded, isTrue);
    expect(await attemptRepository.load(), isNull);
    expect((await trackingRepository.load()).viewedIds, {'card_1'});
  });

  test('rechaza un intento pendiente futuro', () async {
    final backup = service.decode(_backupJson(attemptDate: '2026-07-17'));

    expect(() => service.restore(backup), throwsFormatException);
  });

  test('reinicia progreso, seguimiento e intento', () async {
    await progressRepository.save(const LearnerProgress(
      currentStreak: 2,
      bestStreak: 5,
      shields: 1,
    ));
    await trackingRepository.save(ResourceTracking(
      viewedIds: {'card_1'},
      completedIds: {'card_1'},
    ));
    await attemptRepository.save(_attempt('2026-07-16'));

    await service.reset();

    expect((await progressRepository.load()).currentStreak, 0);
    expect((await trackingRepository.load()).viewedIds, isEmpty);
    expect(await attemptRepository.load(), isNull);
  });
}

DailyAttempt _attempt(String dateKey) {
  return DailyAttempt(
    challengeId: 'reto_1',
    dateKey: dateKey,
    title: 'Reto de prueba',
    kind: ExamKind.dailyScheduled,
    questionIds: const ['MAT-001', 'MAT-002'],
    answers: const {'MAT-001': AnswerOption.a},
    currentIndex: 1,
    startedAt: DateTime(2026, 7, 16, 9),
  );
}

String _backupJson({required String attemptDate}) {
  return jsonEncode({
    'format': ProgressBackupService.format,
    'schema_version': ProgressBackupService.schemaVersion,
    'app_version': '0.7.0',
    'exported_at': '2026-07-16T10:00:00',
    'data': {
      'learner_progress': {
        'current_streak': 3,
        'best_streak': 5,
        'shields': 1,
        'last_completed_date_key': '2026-07-16',
        'last_streak_date_key': '2026-07-16',
        'total_daily_challenges_completed': 7,
        'last_shield_used_date_key': null,
        'last_shield_use_count': 0,
      },
      'daily_attempt': {
        'challenge_id': 'reto_1',
        'date_key': attemptDate,
        'title': 'Reto de prueba',
        'kind': 'DAILY_SCHEDULED',
        'question_ids': ['MAT-001', 'MAT-002'],
        'answers': {'MAT-001': 'A'},
        'current_index': 1,
        'started_at': '2026-07-16T09:00:00',
      },
      'resource_tracking': {
        'viewed_ids': ['card_1'],
        'completed_ids': [],
      },
    },
  });
}

class _FixedClock implements AppClock {
  const _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}
