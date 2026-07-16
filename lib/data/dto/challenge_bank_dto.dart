import 'package:mision_admision/data/dto/daily_challenge_dto.dart';

class ChallengeBankDto {
  ChallengeBankDto({
    required this.schemaVersion,
    required this.version,
    required this.generatedAt,
    required List<DailyChallengeDto> challenges,
    required this.challengesAreObjects,
  }) : challenges = List.unmodifiable(challenges);

  factory ChallengeBankDto.fromJson(Map<String, dynamic> json) {
    final rawChallenges = json['retos'];
    return ChallengeBankDto(
      schemaVersion: json['schema_version'] as int? ?? 0,
      version: json['version'] as String? ?? '',
      generatedAt: json['generated_at'] as String? ?? '',
      challenges: rawChallenges is List
          ? rawChallenges
              .whereType<Map<String, dynamic>>()
              .map(DailyChallengeDto.fromJson)
              .toList(growable: false)
          : const [],
      challengesAreObjects: rawChallenges is List &&
          rawChallenges.every((value) => value is Map<String, dynamic>),
    );
  }

  final int schemaVersion;
  final String version;
  final String generatedAt;
  final List<DailyChallengeDto> challenges;
  final bool challengesAreObjects;
}
