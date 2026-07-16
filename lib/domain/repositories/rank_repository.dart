import 'package:mision_admision/domain/models/rank.dart';

abstract interface class RankRepository {
  Future<List<Rank>> loadRanks();
}
