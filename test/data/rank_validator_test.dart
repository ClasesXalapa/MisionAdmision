import 'package:flutter_test/flutter_test.dart';
import 'package:mision_admision/data/dto/rank_dto.dart';
import 'package:mision_admision/data/validators/rank_validator.dart';

void main() {
  const validator = RankValidator();

  test('exige un rango inicial con umbral cero', () {
    final report = validator.validateBank([
      const RankDto(
        id: 'constante',
        name: 'Constante',
        description: 'Descripción',
        minimumBestStreak: 7,
      ),
    ]);

    expect(report.isValid, isFalse);
    expect(
      report.issues.map((issue) => issue.code),
      contains('missing_initial_rank'),
    );
  });
}
