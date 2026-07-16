import 'package:flutter_test/flutter_test.dart';
import 'package:mision_admision/domain/engines/streak_engine.dart';
import 'package:mision_admision/domain/models/learner_progress.dart';

void main() {
  const engine = StreakEngine();

  test('inicia la racha con el primer reto diario', () {
    final completion = engine.completeDailyChallenge(
      progress: const LearnerProgress(),
      todayDateKey: '2026-07-15',
    );

    expect(completion.countedToday, isTrue);
    expect(completion.progress.currentStreak, 1);
    expect(completion.progress.bestStreak, 1);
    expect(completion.shieldEarned, isFalse);
  });

  test('incrementa la racha y entrega un escudo al llegar a siete días', () {
    final completion = engine.completeDailyChallenge(
      progress: const LearnerProgress(
        currentStreak: 6,
        bestStreak: 8,
        lastCompletedDateKey: '2026-07-14',
        lastStreakDateKey: '2026-07-14',
        totalDailyChallengesCompleted: 10,
      ),
      todayDateKey: '2026-07-15',
    );

    expect(completion.progress.currentStreak, 7);
    expect(completion.progress.bestStreak, 8);
    expect(completion.progress.totalDailyChallengesCompleted, 11);
    expect(completion.progress.shields, 1);
    expect(completion.shieldEarned, isTrue);
  });

  test('respeta el máximo de tres escudos', () {
    final completion = engine.completeDailyChallenge(
      progress: const LearnerProgress(
        currentStreak: 13,
        bestStreak: 13,
        shields: 3,
        lastCompletedDateKey: '2026-07-14',
        lastStreakDateKey: '2026-07-14',
      ),
      todayDateKey: '2026-07-15',
    );

    expect(completion.progress.currentStreak, 14);
    expect(completion.progress.shields, 3);
    expect(completion.shieldEarned, isFalse);
  });

  test('no cuenta dos veces el mismo día', () {
    const progress = LearnerProgress(
      currentStreak: 3,
      bestStreak: 3,
      lastCompletedDateKey: '2026-07-15',
      lastStreakDateKey: '2026-07-15',
      totalDailyChallengesCompleted: 3,
    );

    final completion = engine.completeDailyChallenge(
      progress: progress,
      todayDateKey: '2026-07-15',
    );

    expect(completion.countedToday, isFalse);
    expect(completion.progress.currentStreak, 3);
    expect(completion.progress.totalDailyChallengesCompleted, 3);
  });

  test('un escudo protege una ausencia y permite continuar la racha', () {
    final reconciliation = engine.reconcile(
      progress: const LearnerProgress(
        currentStreak: 7,
        bestStreak: 7,
        shields: 1,
        lastCompletedDateKey: '2026-07-13',
        lastStreakDateKey: '2026-07-13',
      ),
      todayDateKey: '2026-07-15',
    );

    expect(reconciliation.shieldsUsed, 1);
    expect(reconciliation.streakReset, isFalse);
    expect(reconciliation.progress.currentStreak, 7);
    expect(reconciliation.progress.shields, 0);
    expect(reconciliation.progress.lastStreakDateKey, '2026-07-14');

    final completion = engine.completeDailyChallenge(
      progress: reconciliation.progress,
      todayDateKey: '2026-07-15',
    );
    expect(completion.progress.currentStreak, 8);
  });

  test('consume varios escudos para varios días ausentes', () {
    final reconciliation = engine.reconcile(
      progress: const LearnerProgress(
        currentStreak: 14,
        bestStreak: 14,
        shields: 2,
        lastCompletedDateKey: '2026-07-12',
        lastStreakDateKey: '2026-07-12',
      ),
      todayDateKey: '2026-07-15',
    );

    expect(reconciliation.shieldsUsed, 2);
    expect(reconciliation.progress.currentStreak, 14);
    expect(reconciliation.progress.shields, 0);
    expect(reconciliation.progress.lastShieldUseCount, 2);
  });

  test('reinicia la racha cuando no hay suficientes escudos', () {
    final reconciliation = engine.reconcile(
      progress: const LearnerProgress(
        currentStreak: 12,
        bestStreak: 12,
        shields: 1,
        lastCompletedDateKey: '2026-07-10',
        lastStreakDateKey: '2026-07-10',
      ),
      todayDateKey: '2026-07-15',
    );

    expect(reconciliation.shieldsUsed, 1);
    expect(reconciliation.streakReset, isTrue);
    expect(reconciliation.progress.currentStreak, 0);
    expect(reconciliation.progress.bestStreak, 12);
    expect(reconciliation.progress.shields, 0);
  });
}
