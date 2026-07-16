import 'package:mision_admision/domain/models/rank.dart';

class RankEngine {
  const RankEngine();

  Rank resolve({
    required List<Rank> ranks,
    required int bestStreak,
  }) {
    if (ranks.isEmpty) {
      throw StateError('No hay rangos configurados.');
    }

    final ordered = [...ranks]
      ..sort((a, b) => a.minimumBestStreak.compareTo(b.minimumBestStreak));
    var selected = ordered.first;
    for (final rank in ordered) {
      if (rank.minimumBestStreak > bestStreak) {
        break;
      }
      selected = rank;
    }
    return selected;
  }
}
