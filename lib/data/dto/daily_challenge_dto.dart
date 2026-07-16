import 'package:mision_admision/data/dto/resolution_resource_dto.dart';

class DailyChallengeDto {
  DailyChallengeDto({
    required this.id,
    required this.dateKey,
    required this.title,
    required List<String> questionIds,
    required this.resolutionResource,
    this.questionIdsAreStrings = true,
  }) : questionIds = List.unmodifiable(questionIds);

  factory DailyChallengeDto.fromJson(Map<String, dynamic> json) {
    final rawIds = json['preguntas_ids'];
    final rawResource = json['recurso_resolucion'];

    return DailyChallengeDto(
      id: json['id'] as String? ?? '',
      dateKey: json['fecha'] as String? ?? '',
      title: json['titulo'] as String? ?? '',
      questionIds: rawIds is List
          ? rawIds.whereType<String>().toList(growable: false)
          : const [],
      questionIdsAreStrings:
          rawIds is List && rawIds.every((value) => value is String),
      resolutionResource: rawResource is Map<String, dynamic>
          ? ResolutionResourceDto.fromJson(rawResource)
          : null,
    );
  }

  final String id;
  final String dateKey;
  final String title;
  final List<String> questionIds;
  final bool questionIdsAreStrings;
  final ResolutionResourceDto? resolutionResource;
}
