import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mision_admision/data/parsers/content_document_parser.dart';
import 'package:mision_admision/domain/models/answer_option.dart';

void main() {
  const parser = ContentDocumentParser();

  test('mantiene compatibilidad con preguntas de esquema 1', () {
    final questions = parser.parseQuestions(
      jsonEncode(_bank(schemaVersion: 1, includeOptionImages: false)),
    );

    expect(questions, hasLength(1));
    expect(questions.single.optionImageUrls, everyElement(isNull));
  });

  test('acepta texto e imagen independientes en los incisos del esquema 2', () {
    final questions = parser.parseQuestions(
      jsonEncode(_bank(schemaVersion: 2, includeOptionImages: true)),
    );

    final question = questions.single;
    expect(question.optionText(AnswerOption.a), isEmpty);
    expect(
      question.optionImageUrl(AnswerOption.a),
      'https://example.com/opcion-a.png',
    );
  });
}

Map<String, Object?> _bank({
  required int schemaVersion,
  required bool includeOptionImages,
}) {
  return {
    'schema_version': schemaVersion,
    'version': 'questions_test',
    'generated_at': '2026-07-17T22:00:00-06:00',
    'preguntas': [
      {
        'id': 'IMG-001',
        'enunciado': 'Selecciona la figura correcta.',
        'imagen_url': 'https://example.com/pregunta.png',
        'opciones': [
          includeOptionImages ? '' : 'Uno',
          'Dos',
          'Tres',
          'Cuatro',
        ],
        if (includeOptionImages)
          'imagenes_opciones': [
            'https://example.com/opcion-a.png',
            null,
            null,
            null,
          ],
        'respuesta_correcta': 'A',
        'categoria': 'matematicas',
        'etiquetas': ['figuras'],
        'dificultad': 'basico',
      },
    ],
  };
}
