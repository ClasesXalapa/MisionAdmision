import 'package:mision_admision/core/time/local_date.dart';
import 'package:mision_admision/core/validation/validation_issue.dart';
import 'package:mision_admision/core/validation/validation_report.dart';
import 'package:mision_admision/data/dto/daily_challenge_dto.dart';
import 'package:mision_admision/domain/models/daily_challenge.dart';
import 'package:mision_admision/domain/models/exam_kind.dart';

class ChallengeValidator {
  const ChallengeValidator();

  ValidationReport<List<DailyChallenge>> validateBank(
    List<DailyChallengeDto> values,
  ) {
    final issues = <ValidationIssue>[];
    final result = <DailyChallenge>[];
    final ids = <String>{};
    final dates = <String>{};

    for (var index = 0; index < values.length; index += 1) {
      final dto = values[index];
      final path = 'retos[$index]';

      if (dto.id.trim().isEmpty) {
        issues.add(ValidationIssue(code: 'empty_id', path: '$path.id', message: 'ID vacío.'));
      } else if (!ids.add(dto.id.trim())) {
        issues.add(
          ValidationIssue(code: 'duplicate_id', path: '$path.id', message: 'ID duplicado.'),
        );
      }

      try {
        parseLocalDateKey(dto.dateKey);
        if (!dates.add(dto.dateKey)) {
          issues.add(
            ValidationIssue(
              code: 'duplicate_date',
              path: '$path.fecha',
              message: 'Ya existe un reto programado para esta fecha.',
            ),
          );
        }
      } on FormatException catch (error) {
        issues.add(
          ValidationIssue(code: 'invalid_date', path: '$path.fecha', message: error.message.toString()),
        );
      }

      if (dto.title.trim().isEmpty) {
        issues.add(
          ValidationIssue(code: 'empty_title', path: '$path.titulo', message: 'Título vacío.'),
        );
      }

      if (!dto.questionIdsAreStrings) {
        issues.add(
          ValidationIssue(
            code: 'invalid_question_id_type',
            path: '$path.preguntas_ids',
            message: 'Todos los IDs deben ser texto.',
          ),
        );
      } else if (dto.questionIds.isEmpty) {
        issues.add(
          ValidationIssue(
            code: 'empty_question_ids',
            path: '$path.preguntas_ids',
            message: 'Debe contener al menos una pregunta.',
          ),
        );
      } else if (dto.questionIds.toSet().length != dto.questionIds.length) {
        issues.add(
          ValidationIssue(
            code: 'duplicate_question_ids',
            path: '$path.preguntas_ids',
            message: 'No se permiten IDs repetidos.',
          ),
        );
      }

      final resource = dto.resolutionResource;
      if (resource == null) {
        issues.add(
          ValidationIssue(
            code: 'missing_resolution_resource',
            path: '$path.recurso_resolucion',
            message: 'El recurso de resolución es obligatorio.',
          ),
        );
      } else {
        if (resource.type.trim().isEmpty) {
          issues.add(
            ValidationIssue(
              code: 'empty_resolution_type',
              path: '$path.recurso_resolucion.tipo',
              message: 'Tipo vacío.',
            ),
          );
        }
        if (resource.title.trim().isEmpty) {
          issues.add(
            ValidationIssue(
              code: 'empty_resolution_title',
              path: '$path.recurso_resolucion.titulo',
              message: 'Título vacío.',
            ),
          );
        }
        final uri = Uri.tryParse(resource.url.trim());
        if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
          issues.add(
            ValidationIssue(
              code: 'invalid_resolution_url',
              path: '$path.recurso_resolucion.url',
              message: 'Debe ser una URL HTTPS válida.',
            ),
          );
        }
      }

      if (issues.any((issue) => issue.path.startsWith(path))) {
        continue;
      }

      result.add(
        DailyChallenge(
          id: dto.id.trim(),
          dateKey: dto.dateKey,
          title: dto.title.trim(),
          questionIds: dto.questionIds.map((id) => id.trim()).toList(),
          kind: ExamKind.dailyScheduled,
          resolutionResource: resource!.toDomain(),
        ),
      );
    }

    if (issues.isNotEmpty) {
      return ValidationReport.invalid(issues);
    }
    return ValidationReport.valid(List.unmodifiable(result));
  }
}
