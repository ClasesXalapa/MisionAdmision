import 'package:mision_admision/data/dto/question_dto.dart';

class QuestionBankDto {
  const QuestionBankDto({
    required this.schemaVersion,
    required this.version,
    required this.generatedAt,
    required this.questions,
  });

  factory QuestionBankDto.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['preguntas'];
    if (rawQuestions is! List) {
      throw const FormatException('"preguntas" debe ser una lista.');
    }

    final generatedAtRaw = _requiredString(json, 'generated_at');
    final generatedAt = DateTime.tryParse(generatedAtRaw);
    if (generatedAt == null) {
      throw const FormatException(
        'El campo "generated_at" debe utilizar formato ISO 8601.',
      );
    }

    return QuestionBankDto(
      schemaVersion: _requiredInt(json, 'schema_version'),
      version: _requiredNonEmptyString(json, 'version'),
      generatedAt: generatedAt,
      questions: rawQuestions.map((item) {
        if (item is! Map) {
          throw const FormatException(
            'Cada pregunta debe ser un objeto JSON.',
          );
        }
        return QuestionDto.fromJson(Map<String, dynamic>.from(item));
      }).toList(growable: false),
    );
  }

  final int schemaVersion;
  final String version;
  final DateTime generatedAt;
  final List<QuestionDto> questions;
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) {
    throw FormatException('El campo "$key" debe ser entero.');
  }
  return value;
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('El campo "$key" debe ser texto.');
  }
  return value;
}

String _requiredNonEmptyString(Map<String, dynamic> json, String key) {
  final value = _requiredString(json, key).trim();
  if (value.isEmpty) {
    throw FormatException('El campo "$key" no puede estar vacío.');
  }
  return value;
}
