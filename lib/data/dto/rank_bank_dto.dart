import 'package:mision_admision/data/dto/rank_dto.dart';

class RankBankDto {
  const RankBankDto({
    required this.schemaVersion,
    required this.version,
    required this.generatedAt,
    required this.ranks,
  });

  factory RankBankDto.fromJson(Map<String, dynamic> json) {
    final rawRanks = json['rangos'];
    if (rawRanks is! List) {
      throw const FormatException('"rangos" debe ser una lista.');
    }

    final generatedAt = DateTime.tryParse(json['generated_at'] as String? ?? '');
    if (generatedAt == null) {
      throw const FormatException('generated_at debe utilizar ISO 8601.');
    }

    return RankBankDto(
      schemaVersion: json['schema_version'] as int? ?? 0,
      version: json['version'] as String? ?? '',
      generatedAt: generatedAt,
      ranks: rawRanks.map((item) {
        if (item is! Map) {
          throw const FormatException('Cada rango debe ser un objeto JSON.');
        }
        return RankDto.fromJson(Map<String, dynamic>.from(item));
      }).toList(growable: false),
    );
  }

  final int schemaVersion;
  final String version;
  final DateTime generatedAt;
  final List<RankDto> ranks;
}
