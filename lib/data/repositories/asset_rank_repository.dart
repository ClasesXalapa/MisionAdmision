import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:mision_admision/core/errors/content_validation_exception.dart';
import 'package:mision_admision/data/dto/rank_bank_dto.dart';
import 'package:mision_admision/data/validators/rank_validator.dart';
import 'package:mision_admision/domain/models/rank.dart';
import 'package:mision_admision/domain/repositories/rank_repository.dart';

class AssetRankRepository implements RankRepository {
  const AssetRankRepository({
    required this.assetPath,
    this.validator = const RankValidator(),
  });

  final String assetPath;
  final RankValidator validator;

  @override
  Future<List<Rank>> loadRanks() async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('El banco de rangos debe ser un objeto JSON.');
    }

    final bank = RankBankDto.fromJson(decoded);
    if (bank.schemaVersion != 1 || bank.version.trim().isEmpty) {
      throw const FormatException('Metadatos de rangos inválidos.');
    }
    final report = validator.validateBank(bank.ranks);
    if (!report.isValid) {
      throw ContentValidationException(report.issues);
    }
    return report.value!;
  }
}
