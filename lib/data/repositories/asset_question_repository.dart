import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:mision_admision/core/errors/content_validation_exception.dart';
import 'package:mision_admision/data/dto/question_bank_dto.dart';
import 'package:mision_admision/data/validators/question_validator.dart';
import 'package:mision_admision/domain/models/question.dart';
import 'package:mision_admision/domain/repositories/question_repository.dart';

class AssetQuestionRepository implements QuestionRepository {
  const AssetQuestionRepository({
    required this.assetPath,
    this.validator = const QuestionValidator(),
  });

  final String assetPath;
  final QuestionValidator validator;

  @override
  Future<List<Question>> loadQuestions() async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('El banco debe ser un objeto JSON.');
    }

    final bank = QuestionBankDto.fromJson(decoded);
    if (bank.schemaVersion != 1) {
      throw FormatException(
        'Versión de esquema no soportada: ${bank.schemaVersion}.',
      );
    }

    final report = validator.validateBank(bank.questions);
    if (!report.isValid) {
      throw ContentValidationException(report.issues);
    }

    return report.value!;
  }
}
