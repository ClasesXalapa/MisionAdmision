import 'package:flutter_test/flutter_test.dart';
import 'package:mision_admision/data/dto/resource_card_dto.dart';
import 'package:mision_admision/data/validators/resource_validator.dart';
import 'package:mision_admision/domain/models/resource_type.dart';

void main() {
  const validator = ResourceValidator();

  test('acepta una card válida', () {
    final report = validator.validateBank([
      const ResourceCardDto(
        id: 'card_1',
        title: 'Video',
        description: 'Descripción',
        type: 'video',
        url: 'https://example.com/video',
        imageUrl: null,
        tags: ['matematicas'],
        priority: 1,
        publishedDateKey: '2026-07-15',
        active: true,
      ),
    ]);

    expect(report.isValid, isTrue);
    expect(report.value!.single.type, ResourceType.video);
  });

  test('rechaza URL insegura y tipo desconocido', () {
    final report = validator.validateBank([
      const ResourceCardDto(
        id: 'card_1',
        title: 'Recurso',
        description: 'Descripción',
        type: 'otro',
        url: 'http://example.com',
        imageUrl: null,
        tags: ['guia'],
        priority: 1,
        publishedDateKey: '2026-07-15',
        active: true,
      ),
    ]);

    expect(report.isValid, isFalse);
    expect(report.issues.map((issue) => issue.code), contains('invalid_type'));
    expect(report.issues.map((issue) => issue.code), contains('invalid_url'));
  });

  test('omite cards inactivas del resultado', () {
    final report = validator.validateBank([
      const ResourceCardDto(
        id: 'card_1',
        title: 'Recurso',
        description: 'Descripción',
        type: 'pdf',
        url: 'https://example.com/recurso',
        imageUrl: null,
        tags: ['guia'],
        priority: 1,
        publishedDateKey: '2026-07-15',
        active: false,
      ),
    ]);

    expect(report.isValid, isTrue);
    expect(report.value, isEmpty);
  });
}
