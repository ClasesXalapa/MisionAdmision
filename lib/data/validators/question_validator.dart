import 'package:mision_admision/core/validation/validation_issue.dart';
import 'package:mision_admision/core/validation/validation_report.dart';
import 'package:mision_admision/data/dto/question_dto.dart';
import 'package:mision_admision/domain/models/answer_option.dart';
import 'package:mision_admision/domain/models/question.dart';
import 'package:mision_admision/domain/models/question_difficulty.dart';

class QuestionValidator {
  const QuestionValidator();

  ValidationReport<List<Question>> validateBank(List<QuestionDto> dtos) {
    final issues = <ValidationIssue>[];
    final seenIds = <String>{};

    for (var index = 0; index < dtos.length; index += 1) {
      final dto = dtos[index];
      final path = 'preguntas[$index]';

      if (dto.id.trim().isEmpty) {
        issues.add(_issue('empty_id', 'El ID no puede estar vacío.', '$path.id'));
      } else if (!seenIds.add(dto.id.trim())) {
        issues.add(
          _issue('duplicate_id', 'El ID "${dto.id}" está duplicado.', '$path.id'),
        );
      }

      if (dto.statement.trim().isEmpty) {
        issues.add(
          _issue(
            'empty_statement',
            'El enunciado no puede estar vacío.',
            '$path.enunciado',
          ),
        );
      }

      if (dto.options.length != AnswerOption.values.length) {
        issues.add(
          _issue(
            'invalid_option_count',
            'Debe contener exactamente cuatro opciones.',
            '$path.opciones',
          ),
        );
      } else {
        for (var optionIndex = 0;
            optionIndex < dto.options.length;
            optionIndex += 1) {
          if (dto.options[optionIndex].trim().isEmpty) {
            issues.add(
              _issue(
                'empty_option',
                'La opción no puede estar vacía.',
                '$path.opciones[$optionIndex]',
              ),
            );
          }
        }
      }

      if (AnswerOption.tryParse(dto.correctAnswer) == null) {
        issues.add(
          _issue(
            'invalid_answer',
            'La respuesta debe ser A, B, C o D.',
            '$path.respuesta_correcta',
          ),
        );
      }

      if (dto.category.trim().isEmpty) {
        issues.add(
          _issue(
            'empty_category',
            'La categoría no puede estar vacía.',
            '$path.categoria',
          ),
        );
      }

      if (dto.tags.isEmpty || dto.tags.any((tag) => tag.trim().isEmpty)) {
        issues.add(
          _issue(
            'invalid_tags',
            'Debe contener al menos una etiqueta no vacía.',
            '$path.etiquetas',
          ),
        );
      }

      if (QuestionDifficulty.tryParse(dto.difficulty) == null) {
        issues.add(
          _issue(
            'invalid_difficulty',
            'La dificultad debe ser basico, intermedio o avanzado.',
            '$path.dificultad',
          ),
        );
      }

      final imageUrl = dto.imageUrl?.trim();
      if (imageUrl != null && imageUrl.isNotEmpty && !_isValidHttpsUrl(imageUrl)) {
        issues.add(
          _issue(
            'invalid_image_url',
            'La imagen debe utilizar una URL HTTPS válida.',
            '$path.imagen_url',
          ),
        );
      }
    }

    if (issues.isNotEmpty) {
      return ValidationReport.invalid(issues);
    }

    final questions = dtos.map((dto) {
      return Question(
        id: dto.id.trim(),
        statement: dto.statement.trim(),
        imageUrl: _normalizedNullable(dto.imageUrl),
        options: dto.options.map((option) => option.trim()).toList(),
        correctAnswer: AnswerOption.tryParse(dto.correctAnswer)!,
        category: dto.category.trim().toLowerCase(),
        tags: dto.tags.map((tag) => tag.trim().toLowerCase()).toList(),
        difficulty: QuestionDifficulty.tryParse(dto.difficulty)!,
      );
    }).toList(growable: false);

    return ValidationReport.valid(List.unmodifiable(questions));
  }

  ValidationIssue _issue(String code, String message, String path) {
    return ValidationIssue(code: code, message: message, path: path);
  }

  bool _isValidHttpsUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
  }

  String? _normalizedNullable(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
