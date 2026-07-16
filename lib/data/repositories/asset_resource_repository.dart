import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:mision_admision/core/errors/content_validation_exception.dart';
import 'package:mision_admision/data/dto/resource_bank_dto.dart';
import 'package:mision_admision/data/validators/resource_validator.dart';
import 'package:mision_admision/domain/models/resource_card.dart';
import 'package:mision_admision/domain/repositories/resource_repository.dart';

class AssetResourceRepository implements ResourceRepository {
  const AssetResourceRepository({
    required this.assetPath,
    this.validator = const ResourceValidator(),
  });

  final String assetPath;
  final ResourceValidator validator;

  @override
  Future<List<ResourceCard>> loadResources() async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('El banco de cards debe ser un objeto JSON.');
    }
    final bank = ResourceBankDto.fromJson(decoded);
    if (bank.schemaVersion != 1 || bank.version.trim().isEmpty) {
      throw const FormatException('Metadatos de cards inválidos.');
    }
    final report = validator.validateBank(bank.resources);
    if (!report.isValid) {
      throw ContentValidationException(report.issues);
    }
    return report.value!;
  }
}
