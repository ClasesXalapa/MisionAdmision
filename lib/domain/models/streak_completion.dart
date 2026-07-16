import 'package:mision_admision/domain/models/learner_progress.dart';

class StreakCompletion {
  const StreakCompletion({
    required this.progress,
    required this.countedToday,
    required this.shieldEarned,
  });

  final LearnerProgress progress;
  final bool countedToday;
  final bool shieldEarned;
}
