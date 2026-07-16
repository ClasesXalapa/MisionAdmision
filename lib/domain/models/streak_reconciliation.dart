import 'package:mision_admision/domain/models/learner_progress.dart';

class StreakReconciliation {
  const StreakReconciliation({
    required this.progress,
    this.shieldsUsed = 0,
    this.streakReset = false,
  });

  final LearnerProgress progress;
  final int shieldsUsed;
  final bool streakReset;
}
