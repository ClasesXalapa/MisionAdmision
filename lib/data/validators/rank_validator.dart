import 'package:mision_admision/core/validation/validation_issue.dart';
import 'package:mision_admision/core/validation/validation_report.dart';
import 'package:mision_admision/data/dto/rank_dto.dart';
import 'package:mision_admision/domain/models/rank.dart';

class RankValidator {
  const RankValidator();

  ValidationReport<List<Rank>> validateBank(List<RankDto> dtos) {
    final issues = <ValidationIssue>[];
    final ids = <String>{};
    final thresholds = <int>{};

    for (var index = 0; index < dtos.length; index += 1) {
      final dto = dtos[index];
      final path = 'rangos[$index]';
      final id = dto.id.trim();
      if (id.isEmpty) {
        issues.add(_issue('empty_id', 'El ID es obligatorio.', '$path.id'));
      } else if (!ids.add(id)) {
        issues.add(_issue('duplicate_id', 'El ID está duplicado.', '$path.id'));
      }
      if (dto.name.trim().isEmpty) {
        issues.add(_issue('empty_name', 'El nombre es obligatorio.', '$path.nombre'));
      }
      if (dto.description.trim().isEmpty) {
        issues.add(_issue(
          'empty_description',
          'La descripción es obligatoria.',
          '$path.descripcion',
        ));
      }
      if (dto.minimumBestStreak < 0) {
        issues.add(_issue(
          'invalid_threshold',
          'La racha mínima no puede ser negativa.',
          '$path.racha_minima',
        ));
      } else if (!thresholds.add(dto.minimumBestStreak)) {
        issues.add(_issue(
          'duplicate_threshold',
          'La racha mínima no puede repetirse.',
          '$path.racha_minima',
        ));
      }
    }

    if (!thresholds.contains(0)) {
      issues.add(_issue(
        'missing_initial_rank',
        'Debe existir un rango con racha mínima 0.',
        'rangos',
      ));
    }

    if (issues.isNotEmpty) {
      return ValidationReport.invalid(issues);
    }

    final ranks = dtos.map((dto) {
      return Rank(
        id: dto.id.trim(),
        name: dto.name.trim(),
        description: dto.description.trim(),
        minimumBestStreak: dto.minimumBestStreak,
      );
    }).toList(growable: false);
    return ValidationReport.valid(List.unmodifiable(ranks));
  }

  ValidationIssue _issue(String code, String message, String path) {
    return ValidationIssue(code: code, message: message, path: path);
  }
}
