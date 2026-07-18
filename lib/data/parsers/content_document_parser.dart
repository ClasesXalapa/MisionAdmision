import 'dart:convert';

import 'package:mision_admision/core/errors/content_validation_exception.dart';
import 'package:mision_admision/data/dto/challenge_bank_dto.dart';
import 'package:mision_admision/data/dto/question_bank_dto.dart';
import 'package:mision_admision/data/dto/rank_bank_dto.dart';
import 'package:mision_admision/data/dto/resource_bank_dto.dart';
import 'package:mision_admision/data/validators/challenge_validator.dart';
import 'package:mision_admision/data/validators/question_validator.dart';
import 'package:mision_admision/data/validators/rank_validator.dart';
import 'package:mision_admision/data/validators/resource_validator.dart';
import 'package:mision_admision/domain/models/daily_challenge.dart';
import 'package:mision_admision/domain/models/question.dart';
import 'package:mision_admision/domain/models/rank.dart';
import 'package:mision_admision/domain/models/resource_card.dart';

class ContentDocumentParser {
  const ContentDocumentParser({
    this.questionValidator = const QuestionValidator(),
    this.challengeValidator = const ChallengeValidator(),
    this.resourceValidator = const ResourceValidator(),
    this.rankValidator = const RankValidator(),
  });

  final QuestionValidator questionValidator;
  final ChallengeValidator challengeValidator;
  final ResourceValidator resourceValidator;
  final RankValidator rankValidator;

  List<Question> parseQuestions(String raw) {
    final decoded = _decodeObject(raw, 'El banco de preguntas');
    final bank = QuestionBankDto.fromJson(decoded);
    if ((bank.schemaVersion != 1 && bank.schemaVersion != 2) ||
        bank.version.trim().isEmpty) {
      throw const FormatException('Metadatos de preguntas inválidos.');
    }
    final report = questionValidator.validateBank(bank.questions);
    if (!report.isValid) throw ContentValidationException(report.issues);
    return report.value!;
  }

  List<DailyChallenge> parseChallenges(String raw) {
    final decoded = _decodeObject(raw, 'El banco de retos');
    final bank = ChallengeBankDto.fromJson(decoded);
    if (bank.schemaVersion != 1 || bank.version.trim().isEmpty) {
      throw const FormatException('Metadatos de retos inválidos.');
    }
    if (!bank.challengesAreObjects || DateTime.tryParse(bank.generatedAt) == null) {
      throw const FormatException('Estructura del banco de retos inválida.');
    }
    final report = challengeValidator.validateBank(bank.challenges);
    if (!report.isValid) throw ContentValidationException(report.issues);
    return report.value!;
  }

  List<ResourceCard> parseResources(String raw) {
    final decoded = _decodeObject(raw, 'El banco de recursos');
    final bank = ResourceBankDto.fromJson(decoded);
    if (bank.schemaVersion != 1 || bank.version.trim().isEmpty) {
      throw const FormatException('Metadatos de recursos inválidos.');
    }
    final report = resourceValidator.validateBank(bank.resources);
    if (!report.isValid) throw ContentValidationException(report.issues);
    return report.value!;
  }

  List<Rank> parseRanks(String raw) {
    final decoded = _decodeObject(raw, 'El banco de rangos');
    final bank = RankBankDto.fromJson(decoded);
    if (bank.schemaVersion != 1 || bank.version.trim().isEmpty) {
      throw const FormatException('Metadatos de rangos inválidos.');
    }
    final report = rankValidator.validateBank(bank.ranks);
    if (!report.isValid) throw ContentValidationException(report.issues);
    return report.value!;
  }

  Map<String, dynamic> _decodeObject(String raw, String label) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw FormatException('$label debe contener un objeto JSON.');
    }
    return Map<String, dynamic>.from(decoded);
  }
}
