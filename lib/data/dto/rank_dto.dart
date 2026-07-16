class RankDto {
  const RankDto({
    required this.id,
    required this.name,
    required this.description,
    required this.minimumBestStreak,
  });

  factory RankDto.fromJson(Map<String, dynamic> json) {
    return RankDto(
      id: json['id'] as String? ?? '',
      name: json['nombre'] as String? ?? '',
      description: json['descripcion'] as String? ?? '',
      minimumBestStreak: json['racha_minima'] as int? ?? -1,
    );
  }

  final String id;
  final String name;
  final String description;
  final int minimumBestStreak;
}
