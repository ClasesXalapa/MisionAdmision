import 'package:mision_admision/domain/models/learner_progress.dart';

abstract interface class ProgressRepository {
  Future<LearnerProgress> load();

  Future<void> save(LearnerProgress progress);
}
