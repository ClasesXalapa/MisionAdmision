import 'package:flutter_test/flutter_test.dart';
import 'package:mision_admision/data/dto/daily_challenge_dto.dart';
import 'package:mision_admision/data/dto/resolution_resource_dto.dart';
import 'package:mision_admision/data/validators/challenge_validator.dart';

void main() {
  const validator = ChallengeValidator();

  test('acepta un reto programado válido', () {
    final report = validator.validateBank([_validChallenge()]);

    expect(report.isValid, isTrue);
    expect(report.value, hasLength(1));
  });

  test('rechaza dos retos para la misma fecha', () {
    final report = validator.validateBank([
      _validChallenge(id: 'reto_1'),
      _validChallenge(id: 'reto_2'),
    ]);

    expect(report.isValid, isFalse);
    expect(
      report.issues.any((issue) => issue.code == 'duplicate_date'),
      isTrue,
    );
  });

  test('exige recurso de resolución', () {
    final challenge = DailyChallengeDto(
      id: 'reto_1',
      dateKey: '2026-07-15',
      title: 'Reto',
      questionIds: const ['Q-1'],
      resolutionResource: null,
    );

    final report = validator.validateBank([challenge]);

    expect(report.isValid, isFalse);
    expect(
      report.issues.any(
        (issue) => issue.code == 'missing_resolution_resource',
      ),
      isTrue,
    );
  });
}

DailyChallengeDto _validChallenge({String id = 'reto_1'}) {
  return DailyChallengeDto(
    id: id,
    dateKey: '2026-07-15',
    title: 'Reto',
    questionIds: const ['Q-1', 'Q-2'],
    resolutionResource: const ResolutionResourceDto(
      type: 'video',
      title: 'Resolución',
      url: 'https://example.com/resolucion',
    ),
  );
}
