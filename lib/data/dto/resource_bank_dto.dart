import 'package:mision_admision/data/dto/resource_card_dto.dart';

class ResourceBankDto {
  const ResourceBankDto({
    required this.schemaVersion,
    required this.version,
    required this.generatedAt,
    required this.resources,
  });

  factory ResourceBankDto.fromJson(Map<String, dynamic> json) {
    final rawResources = json['cards'];
    if (rawResources is! List) {
      throw const FormatException('"cards" debe ser una lista.');
    }
    final generatedAt = DateTime.tryParse(json['generated_at'] as String? ?? '');
    if (generatedAt == null) {
      throw const FormatException('generated_at debe utilizar ISO 8601.');
    }

    return ResourceBankDto(
      schemaVersion: json['schema_version'] as int? ?? 0,
      version: json['version'] as String? ?? '',
      generatedAt: generatedAt,
      resources: rawResources.map((item) {
        if (item is! Map) {
          throw const FormatException('Cada card debe ser un objeto JSON.');
        }
        return ResourceCardDto.fromJson(Map<String, dynamic>.from(item));
      }).toList(growable: false),
    );
  }

  final int schemaVersion;
  final String version;
  final DateTime generatedAt;
  final List<ResourceCardDto> resources;
}
