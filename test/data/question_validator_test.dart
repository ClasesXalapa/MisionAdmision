import 'package:flutter_test/flutter_test.dart';
import 'package:mision_admision/data/dto/question_dto.dart';
import 'package:mision_admision/data/validators/question_validator.dart';

void main() {
  const validator = QuestionValidator();

  test('acepta un banco válido', () {
    final report = validator.validateBank([_validQuestion()]);

    expect(report.isValid, isTrue);
    expect(report.value, hasLength(1));
    expect(report.issues, isEmpty);
  });

  test('rechaza IDs duplicados', () {
    final report = validator.validateBank([
      _validQuestion(),
      _validQuestion(),
    ]);

    expect(report.isValid, isFalse);
    expect(
      report.issues.any((issue) => issue.code == 'duplicate_id'),
      isTrue,
    );
  });

  test('rechaza una respuesta fuera de A, B, C o D', () {
    final report = validator.validateBank([
      _validQuestion(correctAnswer: 'E'),
    ]);

    expect(report.isValid, isFalse);
    expect(
      report.issues.any((issue) => issue.code == 'invalid_answer'),
      isTrue,
    );
  });

  test('rechaza bancos con una cantidad distinta de cuatro opciones', () {
    final report = validator.validateBank([
      _validQuestion(options: const ['1', '2', '3']),
    ]);

    expect(report.isValid, isFalse);
    expect(
      report.issues.any((issue) => issue.code == 'invalid_option_count'),
      isTrue,
    );
  });
}

QuestionDto _validQuestion({
  String correctAnswer = 'A',
  List<String> options = const ['1', '2', '3', '4'],
}) {
  return QuestionDto(
    id: 'MAT-001',
    statement: '¿Cuánto es 1 + 1?',
    options: options,
    correctAnswer: correctAnswer,
    category: 'matematicas',
    tags: const ['aritmetica'],
    difficulty: 'basico',
  );
}
