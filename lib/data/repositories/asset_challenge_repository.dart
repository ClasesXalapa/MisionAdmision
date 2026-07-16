import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:mision_admision/core/errors/content_validation_exception.dart';
import 'package:mision_admision/data/dto/challenge_bank_dto.dart';
import 'package:mision_admision/data/validators/challenge_validator.dart';
import 'package:mision_admision/domain/models/daily_challenge.dart';
import 'package:mision_admision/domain/repositories/challenge_repository.dart';

class AssetChallengeRepository implements ChallengeRepository {
  const AssetChallengeRepository({
    required this.assetPath,
    this.validator = const ChallengeValidator(),
  });

  final String assetPath;
  final ChallengeValidator validator;

  @override
  Future<List<DailyChallenge>> loadScheduledChallenges() async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('El banco de retos debe ser un objeto JSON.');
    }

    final bank = ChallengeBankDto.fromJson(decoded);
    if (bank.schemaVersion != 1) {
      throw FormatException(
        'Versión de esquema de retos no soportada: ${bank.schemaVersion}.',
      );
    }
    if (!bank.challengesAreObjects) {
      throw const FormatException(
        'Todos los elementos del banco de retos deben ser objetos.',
      );
    }
    if (bank.version.trim().isEmpty) {
      throw const FormatException('La versión del banco de retos está vacía.');
    }
    if (DateTime.tryParse(bank.generatedAt) == null) {
      throw const FormatException(
        'La fecha de generación del banco de retos es inválida.',
      );
    }

    final report = validator.validateBank(bank.challenges);
    if (!report.isValid) {
      throw ContentValidationException(report.issues);
    }
    return report.value!;
  }
}
