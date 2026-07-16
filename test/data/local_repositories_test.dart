import 'package:flutter_test/flutter_test.dart';
import 'package:mision_admision/data/repositories/local_daily_attempt_repository.dart';
import 'package:mision_admision/data/repositories/local_progress_repository.dart';
import 'package:mision_admision/data/repositories/local_resource_tracking_repository.dart';
import 'package:mision_admision/domain/models/answer_option.dart';
import 'package:mision_admision/domain/models/daily_attempt.dart';
import 'package:mision_admision/domain/models/exam_kind.dart';
import 'package:mision_admision/domain/models/learner_progress.dart';
import 'package:mision_admision/domain/models/resource_tracking.dart';

import '../helpers/memory_json_store.dart';

void main() {
  test('guarda y restaura un intento diario', () async {
    final store = MemoryJsonStore();
    final repository = LocalDailyAttemptRepository(store: store);
    final attempt = DailyAttempt(
      challengeId: 'reto_1',
      dateKey: '2026-07-15',
      title: 'Reto',
      kind: ExamKind.dailyAutomatic,
      questionIds: const ['Q-1', 'Q-2'],
      answers: const {'Q-1': AnswerOption.b},
      currentIndex: 1,
      startedAt: DateTime.parse('2026-07-15T10:00:00-06:00'),
    );

    await repository.save(attempt);
    final restored = await repository.load();

    expect(restored, isNotNull);
    expect(restored!.challengeId, attempt.challengeId);
    expect(restored.answers['Q-1'], AnswerOption.b);
    expect(restored.currentIndex, 1);
  });

  test('elimina un intento local corrupto', () async {
    final store = MemoryJsonStore();
    final repository = LocalDailyAttemptRepository(store: store);
    store.values['mision_admision.daily_attempt.v1'] = '{mal json';

    expect(await repository.load(), isNull);
    expect(store.values, isEmpty);
  });

  test('guarda y restaura el progreso', () async {
    final store = MemoryJsonStore();
    final repository = LocalProgressRepository(store: store);
    const progress = LearnerProgress(
      currentStreak: 5,
      bestStreak: 9,
      lastCompletedDateKey: '2026-07-15',
      totalDailyChallengesCompleted: 14,
    );

    await repository.save(progress);
    final restored = await repository.load();

    expect(restored.currentStreak, 5);
    expect(restored.bestStreak, 9);
    expect(restored.lastCompletedDateKey, '2026-07-15');
    expect(restored.totalDailyChallengesCompleted, 14);
  });

  test('migra el progreso anterior y usa la última fecha como ancla', () async {
    final store = MemoryJsonStore();
    final repository = LocalProgressRepository(store: store);
    store.values['mision_admision.learner_progress.v1'] =
        '{"current_streak":5,"best_streak":8,'
        '"last_completed_date_key":"2026-07-15",'
        '"total_daily_challenges_completed":9}';

    final restored = await repository.load();

    expect(restored.currentStreak, 5);
    expect(restored.lastStreakDateKey, '2026-07-15');
    expect(restored.shields, 0);
  });

  test('guarda cards vistas y completadas', () async {
    final store = MemoryJsonStore();
    final repository = LocalResourceTrackingRepository(store: store);
    final tracking = ResourceTracking(
      viewedIds: const {'card_1', 'card_2'},
      completedIds: const {'card_2'},
    );

    await repository.save(tracking);
    final restored = await repository.load();

    expect(restored.isViewed('card_1'), isTrue);
    expect(restored.isCompleted('card_2'), isTrue);
    expect(restored.isCompleted('card_1'), isFalse);
  });

}
