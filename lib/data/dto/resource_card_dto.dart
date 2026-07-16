class ResourceCardDto {
  const ResourceCardDto({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.url,
    required this.imageUrl,
    required this.tags,
    required this.priority,
    required this.publishedDateKey,
    required this.active,
  });

  factory ResourceCardDto.fromJson(Map<String, dynamic> json) {
    final rawTags = json['etiquetas'];
    return ResourceCardDto(
      id: json['id'] as String? ?? '',
      title: json['titulo'] as String? ?? '',
      description: json['descripcion'] as String? ?? '',
      type: json['tipo'] as String? ?? '',
      url: json['url'] as String? ?? '',
      imageUrl: json['imagen_url'] as String?,
      tags: rawTags is List ? rawTags.whereType<String>().toList() : const [],
      priority: json['prioridad'] as int? ?? -1,
      publishedDateKey: json['fecha_publicacion'] as String? ?? '',
      active: json['activa'] as bool? ?? false,
    );
  }

  final String id;
  final String title;
  final String description;
  final String type;
  final String url;
  final String? imageUrl;
  final List<String> tags;
  final int priority;
  final String publishedDateKey;
  final bool active;
}
