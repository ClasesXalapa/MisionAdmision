import 'package:mision_admision/core/time/local_date.dart';
import 'package:mision_admision/domain/models/learner_progress.dart';

class LearnerProgressDto {
  const LearnerProgressDto({
    required this.currentStreak,
    required this.bestStreak,
    required this.shields,
    required this.lastCompletedDateKey,
    required this.lastStreakDateKey,
    required this.totalDailyChallengesCompleted,
    required this.lastShieldUsedDateKey,
    required this.lastShieldUseCount,
  });

  factory LearnerProgressDto.fromDomain(LearnerProgress progress) {
    return LearnerProgressDto(
      currentStreak: progress.currentStreak,
      bestStreak: progress.bestStreak,
      shields: progress.shields,
      lastCompletedDateKey: progress.lastCompletedDateKey,
      lastStreakDateKey: progress.lastStreakDateKey,
      totalDailyChallengesCompleted: progress.totalDailyChallengesCompleted,
      lastShieldUsedDateKey: progress.lastShieldUsedDateKey,
      lastShieldUseCount: progress.lastShieldUseCount,
    );
  }

  factory LearnerProgressDto.fromJson(Map<String, dynamic> json) {
    final lastCompleted = json['last_completed_date_key'] as String?;
    return LearnerProgressDto(
      currentStreak: json['current_streak'] as int? ?? 0,
      bestStreak: json['best_streak'] as int? ?? 0,
      shields: json['shields'] as int? ?? 0,
      lastCompletedDateKey: lastCompleted,
      lastStreakDateKey:
          json['last_streak_date_key'] as String? ?? lastCompleted,
      totalDailyChallengesCompleted:
          json['total_daily_challenges_completed'] as int? ?? 0,
      lastShieldUsedDateKey: json['last_shield_used_date_key'] as String?,
      lastShieldUseCount: json['last_shield_use_count'] as int? ?? 0,
    );
  }

  final int currentStreak;
  final int bestStreak;
  final int shields;
  final String? lastCompletedDateKey;
  final String? lastStreakDateKey;
  final int totalDailyChallengesCompleted;
  final String? lastShieldUsedDateKey;
  final int lastShieldUseCount;

  Map<String, dynamic> toJson() {
    return {
      'current_streak': currentStreak,
      'best_streak': bestStreak,
      'shields': shields,
      'last_completed_date_key': lastCompletedDateKey,
      'last_streak_date_key': lastStreakDateKey,
      'total_daily_challenges_completed': totalDailyChallengesCompleted,
      'last_shield_used_date_key': lastShieldUsedDateKey,
      'last_shield_use_count': lastShieldUseCount,
    };
  }

  LearnerProgress toDomain() {
    if (currentStreak < 0 ||
        bestStreak < 0 ||
        shields < 0 ||
        shields > LearnerProgress.maximumShields ||
        totalDailyChallengesCompleted < 0 ||
        lastShieldUseCount < 0 ||
        bestStreak < currentStreak) {
      throw const FormatException('El progreso local contiene valores inválidos.');
    }

    for (final value in [
      lastCompletedDateKey,
      lastStreakDateKey,
      lastShieldUsedDateKey,
    ]) {
      if (value != null) {
        parseLocalDateKey(value);
      }
    }

    return LearnerProgress(
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      shields: shields,
      lastCompletedDateKey: lastCompletedDateKey,
      lastStreakDateKey: lastStreakDateKey,
      totalDailyChallengesCompleted: totalDailyChallengesCompleted,
      lastShieldUsedDateKey: lastShieldUsedDateKey,
      lastShieldUseCount: lastShieldUseCount,
    );
  }
}
