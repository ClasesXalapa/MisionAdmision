import 'dart:math';

import 'package:mision_admision/core/time/local_date.dart';
import 'package:mision_admision/domain/models/learner_progress.dart';
import 'package:mision_admision/domain/models/streak_completion.dart';
import 'package:mision_admision/domain/models/streak_reconciliation.dart';

class StreakEngine {
  const StreakEngine();

  StreakReconciliation reconcile({
    required LearnerProgress progress,
    required String todayDateKey,
  }) {
    final anchor = progress.lastStreakDateKey ?? progress.lastCompletedDateKey;
    if (anchor == null || progress.currentStreak == 0) {
      return StreakReconciliation(progress: progress);
    }

    final gap = localDayDifference(anchor, todayDateKey);
    final missedDays = max(0, gap - 1);
    if (missedDays == 0) {
      return StreakReconciliation(progress: progress);
    }

    final shieldsUsed = min(progress.shields, missedDays);
    final shieldsRemaining = progress.shields - shieldsUsed;
    final protectedEveryMissedDay = shieldsUsed == missedDays;

    if (protectedEveryMissedDay) {
      final updated = progress.copyWith(
        shields: shieldsRemaining,
        lastStreakDateKey: addLocalDays(todayDateKey, -1),
        lastShieldUsedDateKey: todayDateKey,
        lastShieldUseCount: shieldsUsed,
      );
      return StreakReconciliation(
        progress: updated,
        shieldsUsed: shieldsUsed,
      );
    }

    final updated = progress.copyWith(
      currentStreak: 0,
      shields: shieldsRemaining,
      clearLastStreakDateKey: true,
      lastShieldUsedDateKey: shieldsUsed > 0 ? todayDateKey : null,
      clearLastShieldUsedDateKey: shieldsUsed == 0,
      lastShieldUseCount: shieldsUsed,
    );
    return StreakReconciliation(
      progress: updated,
      shieldsUsed: shieldsUsed,
      streakReset: true,
    );
  }

  LearnerProgress normalize({
    required LearnerProgress progress,
    required String todayDateKey,
  }) {
    return reconcile(
      progress: progress,
      todayDateKey: todayDateKey,
    ).progress;
  }

  StreakCompletion completeDailyChallenge({
    required LearnerProgress progress,
    required String todayDateKey,
  }) {
    if (progress.lastCompletedDateKey == todayDateKey) {
      return StreakCompletion(
        progress: progress,
        countedToday: false,
        shieldEarned: false,
      );
    }

    final anchor = progress.lastStreakDateKey ?? progress.lastCompletedDateKey;
    final isConsecutive = anchor != null &&
        progress.currentStreak > 0 &&
        localDayDifference(anchor, todayDateKey) == 1;
    final newCurrent = isConsecutive ? progress.currentStreak + 1 : 1;
    final canEarnShield = newCurrent % 7 == 0 &&
        progress.shields < LearnerProgress.maximumShields;
    final newShields = canEarnShield ? progress.shields + 1 : progress.shields;

    final updated = LearnerProgress(
      currentStreak: newCurrent,
      bestStreak: max(progress.bestStreak, newCurrent),
      shields: newShields,
      lastCompletedDateKey: todayDateKey,
      lastStreakDateKey: todayDateKey,
      totalDailyChallengesCompleted:
          progress.totalDailyChallengesCompleted + 1,
      lastShieldUsedDateKey: progress.lastShieldUsedDateKey,
      lastShieldUseCount: progress.lastShieldUseCount,
    );

    return StreakCompletion(
      progress: updated,
      countedToday: true,
      shieldEarned: canEarnShield,
    );
  }
}
