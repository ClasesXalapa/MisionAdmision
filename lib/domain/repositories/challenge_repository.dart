import 'package:mision_admision/domain/models/daily_challenge.dart';

abstract interface class ChallengeRepository {
  Future<List<DailyChallenge>> loadScheduledChallenges();
}
