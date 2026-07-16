import 'package:mision_admision/domain/models/daily_attempt.dart';
import 'package:mision_admision/domain/models/learner_progress.dart';
import 'package:mision_admision/domain/models/resource_tracking.dart';

class ProgressBackup {
  const ProgressBackup({
    required this.exportedAt,
    required this.appVersion,
    required this.progress,
    required this.tracking,
    this.dailyAttempt,
  });

  final DateTime exportedAt;
  final String appVersion;
  final LearnerProgress progress;
  final ResourceTracking tracking;
  final DailyAttempt? dailyAttempt;
}

class ProgressImportResult {
  const ProgressImportResult({
    required this.progress,
    required this.tracking,
    required this.attemptRestored,
    required this.staleAttemptDiscarded,
  });

  final LearnerProgress progress;
  final ResourceTracking tracking;
  final bool attemptRestored;
  final bool staleAttemptDiscarded;
}
