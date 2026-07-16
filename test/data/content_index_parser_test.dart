import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mision_admision/data/parsers/content_index_parser.dart';
import 'package:mision_admision/domain/models/content_file_kind.dart';

void main() {
  const parser = ContentIndexParser();

  test('acepta un índice completo y válido', () {
    final index = parser.parse(jsonEncode(_validIndex()));

    expect(index.contentVersion, 'content_001');
    expect(index.files, hasLength(4));
    expect(index.files[ContentFileKind.questions]!.required, isTrue);
  });

  test('rechaza un índice sin banco de rangos', () {
    final json = _validIndex();
    (json['files'] as Map<String, dynamic>).remove('ranks');

    expect(
      () => parser.parse(jsonEncode(json)),
      throwsA(isA<FormatException>()),
    );
  });

  test('rechaza tipos de archivo desconocidos', () {
    final json = _validIndex();
    (json['files'] as Map<String, dynamic>)['extra'] = {
      'url': 'content/extra.json',
      'version': 'extra_001',
      'required': false,
    };

    expect(
      () => parser.parse(jsonEncode(json)),
      throwsA(isA<FormatException>()),
    );
  });

  test('rechaza archivos opcionales marcados como obligatorios', () {
    final json = _validIndex();
    ((json['files'] as Map<String, dynamic>)['resources']
        as Map<String, dynamic>)['required'] = true;

    expect(
      () => parser.parse(jsonEncode(json)),
      throwsA(isA<FormatException>()),
    );
  });

  test('rechaza una versión general con caracteres inseguros', () {
    final json = _validIndex()..['content_version'] = 'content/001';

    expect(
      () => parser.parse(jsonEncode(json)),
      throwsA(isA<FormatException>()),
    );
  });

  test('rechaza rutas que intentan salir del directorio', () {
    final json = _validIndex();
    ((json['files'] as Map<String, dynamic>)['resources']
        as Map<String, dynamic>)['url'] = '../cards.json';

    expect(
      () => parser.parse(jsonEncode(json)),
      throwsA(isA<FormatException>()),
    );
  });
}

Map<String, dynamic> _validIndex() => {
      'schema_version': 1,
      'content_version': 'content_001',
      'generated_at': '2026-07-15T12:00:00-06:00',
      'min_app_version': 1,
      'files': {
        'questions': {
          'url': 'content/preguntas/banco_global.json',
          'version': 'questions_001',
          'required': true,
        },
        'challenges': {
          'url': 'content/retos/retos_actuales.json',
          'version': 'challenges_001',
          'required': false,
        },
        'resources': {
          'url': 'content/cards/cards_actuales.json',
          'version': 'resources_001',
          'required': false,
        },
        'ranks': {
          'url': 'content/config/rangos.json',
          'version': 'ranks_001',
          'required': false,
        },
      },
    };
