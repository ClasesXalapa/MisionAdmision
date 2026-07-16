import 'package:flutter_test/flutter_test.dart';
import 'package:mision_admision/domain/engines/rank_engine.dart';
import 'package:mision_admision/domain/models/rank.dart';

void main() {
  const engine = RankEngine();
  const ranks = [
    Rank(
      id: 'inicio',
      name: 'Primer paso',
      description: 'Inicio',
      minimumBestStreak: 0,
    ),
    Rank(
      id: 'constante',
      name: 'Constante',
      description: 'Semana',
      minimumBestStreak: 7,
    ),
    Rank(
      id: 'serio',
      name: 'Aspirante serio',
      description: 'Mes',
      minimumBestStreak: 30,
    ),
  ];

  test('elige el rango más alto alcanzado', () {
    final rank = engine.resolve(ranks: ranks, bestStreak: 18);
    expect(rank.id, 'constante');
  });

  test('el rango depende de la mejor racha y no de la actual', () {
    final rank = engine.resolve(ranks: ranks, bestStreak: 30);
    expect(rank.id, 'serio');
  });
}
