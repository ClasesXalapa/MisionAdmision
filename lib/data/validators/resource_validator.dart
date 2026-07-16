import 'package:mision_admision/core/time/local_date.dart';
import 'package:mision_admision/core/validation/validation_issue.dart';
import 'package:mision_admision/core/validation/validation_report.dart';
import 'package:mision_admision/data/dto/resource_card_dto.dart';
import 'package:mision_admision/domain/models/resource_card.dart';
import 'package:mision_admision/domain/models/resource_type.dart';

class ResourceValidator {
  const ResourceValidator();

  ValidationReport<List<ResourceCard>> validateBank(List<ResourceCardDto> dtos) {
    final issues = <ValidationIssue>[];
    final ids = <String>{};

    for (var index = 0; index < dtos.length; index += 1) {
      final dto = dtos[index];
      final path = 'cards[$index]';
      final id = dto.id.trim();
      if (id.isEmpty) {
        issues.add(_issue('empty_id', 'El ID es obligatorio.', '$path.id'));
      } else if (!ids.add(id)) {
        issues.add(_issue('duplicate_id', 'El ID está duplicado.', '$path.id'));
      }
      if (dto.title.trim().isEmpty) {
        issues.add(_issue('empty_title', 'El título es obligatorio.', '$path.titulo'));
      }
      if (dto.description.trim().isEmpty) {
        issues.add(_issue(
          'empty_description',
          'La descripción es obligatoria.',
          '$path.descripcion',
        ));
      }
      if (ResourceType.tryParse(dto.type) == null) {
        issues.add(_issue('invalid_type', 'El tipo no es válido.', '$path.tipo'));
      }
      if (!_isHttps(dto.url)) {
        issues.add(_issue('invalid_url', 'La URL debe usar HTTPS.', '$path.url'));
      }
      final image = dto.imageUrl?.trim();
      if (image != null && image.isNotEmpty && !_isHttps(image)) {
        issues.add(_issue(
          'invalid_image_url',
          'La imagen debe usar HTTPS.',
          '$path.imagen_url',
        ));
      }
      if (dto.tags.isEmpty || dto.tags.any((tag) => tag.trim().isEmpty)) {
        issues.add(_issue(
          'invalid_tags',
          'Debe incluir etiquetas no vacías.',
          '$path.etiquetas',
        ));
      }
      if (dto.priority < 0) {
        issues.add(_issue(
          'invalid_priority',
          'La prioridad no puede ser negativa.',
          '$path.prioridad',
        ));
      }
      try {
        parseLocalDateKey(dto.publishedDateKey);
      } on FormatException {
        issues.add(_issue(
          'invalid_date',
          'La fecha debe usar YYYY-MM-DD.',
          '$path.fecha_publicacion',
        ));
      }
    }

    if (issues.isNotEmpty) {
      return ValidationReport.invalid(issues);
    }

    final cards = dtos.where((dto) => dto.active).map((dto) {
      return ResourceCard(
        id: dto.id.trim(),
        title: dto.title.trim(),
        description: dto.description.trim(),
        type: ResourceType.tryParse(dto.type)!,
        url: Uri.parse(dto.url.trim()),
        imageUrl: _nullableUri(dto.imageUrl),
        tags: dto.tags.map((tag) => tag.trim().toLowerCase()).toSet().toList(),
        priority: dto.priority,
        publishedDateKey: dto.publishedDateKey,
      );
    }).toList(growable: false)
      ..sort((a, b) {
        final priority = a.priority.compareTo(b.priority);
        if (priority != 0) return priority;
        return b.publishedDateKey.compareTo(a.publishedDateKey);
      });
    return ValidationReport.valid(List.unmodifiable(cards));
  }

  bool _isHttps(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
  }

  Uri? _nullableUri(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : Uri.parse(normalized);
  }

  ValidationIssue _issue(String code, String message, String path) {
    return ValidationIssue(code: code, message: message, path: path);
  }
}
