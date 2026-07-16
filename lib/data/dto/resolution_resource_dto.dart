import 'package:mision_admision/domain/models/resolution_resource.dart';

class ResolutionResourceDto {
  const ResolutionResourceDto({
    required this.type,
    required this.title,
    required this.url,
  });

  factory ResolutionResourceDto.fromJson(Map<String, dynamic> json) {
    return ResolutionResourceDto(
      type: json['tipo'] as String? ?? '',
      title: json['titulo'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
  }

  final String type;
  final String title;
  final String url;

  ResolutionResource toDomain() {
    return ResolutionResource(
      type: type.trim(),
      title: title.trim(),
      url: Uri.parse(url.trim()),
    );
  }
}
