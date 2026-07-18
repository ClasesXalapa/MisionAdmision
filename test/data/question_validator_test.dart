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

  test('acepta un inciso compuesto únicamente por una imagen HTTPS', () {
    final report = validator.validateBank([
      _validQuestion(
        options: const ['', '2', '3', '4'],
        optionImageUrls: const [
          'https://example.com/opcion-a.png',
          null,
          null,
          null,
        ],
      ),
    ]);

    expect(report.isValid, isTrue);
    expect(
      report.value!.single.optionImageUrls.first,
      'https://example.com/opcion-a.png',
    );
  });

  test('rechaza imágenes de incisos que no sean HTTPS', () {
    final report = validator.validateBank([
      _validQuestion(
        optionImageUrls: const [
          'http://example.com/opcion-a.png',
          null,
          null,
          null,
        ],
      ),
    ]);

    expect(report.isValid, isFalse);
    expect(
      report.issues.any(
        (issue) => issue.code == 'invalid_option_image_url',
      ),
      isTrue,
    );
  });
}

QuestionDto _validQuestion({
  String correctAnswer = 'A',
  List<String> options = const ['1', '2', '3', '4'],
  List<String?> optionImageUrls = const [null, null, null, null],
}) {
  return QuestionDto(
    id: 'MAT-001',
    statement: '¿Cuánto es 1 + 1?',
    options: options,
    optionImageUrls: optionImageUrls,
    correctAnswer: correctAnswer,
    category: 'matematicas',
    tags: const ['aritmetica'],
    difficulty: 'basico',
  );
}
