import 'package:mision_admision/domain/models/daily_attempt.dart';

abstract interface class DailyAttemptRepository {
  Future<DailyAttempt?> load();

  Future<void> save(DailyAttempt attempt);

  Future<void> clear();
}
