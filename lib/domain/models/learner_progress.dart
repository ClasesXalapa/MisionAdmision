class LearnerProgress {
  const LearnerProgress({
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.shields = 0,
    this.lastCompletedDateKey,
    this.lastStreakDateKey,
    this.totalDailyChallengesCompleted = 0,
    this.lastShieldUsedDateKey,
    this.lastShieldUseCount = 0,
  });

  static const int maximumShields = 3;

  final int currentStreak;
  final int bestStreak;
  final int shields;
  final String? lastCompletedDateKey;
  final String? lastStreakDateKey;
  final int totalDailyChallengesCompleted;
  final String? lastShieldUsedDateKey;
  final int lastShieldUseCount;

  LearnerProgress copyWith({
    int? currentStreak,
    int? bestStreak,
    int? shields,
    String? lastCompletedDateKey,
    bool clearLastCompletedDateKey = false,
    String? lastStreakDateKey,
    bool clearLastStreakDateKey = false,
    int? totalDailyChallengesCompleted,
    String? lastShieldUsedDateKey,
    bool clearLastShieldUsedDateKey = false,
    int? lastShieldUseCount,
  }) {
    return LearnerProgress(
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      shields: shields ?? this.shields,
      lastCompletedDateKey: clearLastCompletedDateKey
          ? null
          : lastCompletedDateKey ?? this.lastCompletedDateKey,
      lastStreakDateKey: clearLastStreakDateKey
          ? null
          : lastStreakDateKey ?? this.lastStreakDateKey,
      totalDailyChallengesCompleted:
          totalDailyChallengesCompleted ?? this.totalDailyChallengesCompleted,
      lastShieldUsedDateKey: clearLastShieldUsedDateKey
          ? null
          : lastShieldUsedDateKey ?? this.lastShieldUsedDateKey,
      lastShieldUseCount: lastShieldUseCount ?? this.lastShieldUseCount,
    );
  }
}
