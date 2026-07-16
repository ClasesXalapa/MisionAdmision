import 'package:mision_admision/domain/models/resource_type.dart';

class ResourceCard {
  ResourceCard({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.url,
    required List<String> tags,
    required this.priority,
    required this.publishedDateKey,
    this.imageUrl,
  }) : tags = List.unmodifiable(tags);

  final String id;
  final String title;
  final String description;
  final ResourceType type;
  final Uri url;
  final Uri? imageUrl;
  final List<String> tags;
  final int priority;
  final String publishedDateKey;
}
