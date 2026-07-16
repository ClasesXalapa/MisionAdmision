import 'package:mision_admision/domain/models/resource_tracking.dart';

class ResourceTrackingDto {
  const ResourceTrackingDto({
    required this.viewedIds,
    required this.completedIds,
  });

  factory ResourceTrackingDto.fromDomain(ResourceTracking tracking) {
    return ResourceTrackingDto(
      viewedIds: tracking.viewedIds.toList()..sort(),
      completedIds: tracking.completedIds.toList()..sort(),
    );
  }

  factory ResourceTrackingDto.fromJson(Map<String, dynamic> json) {
    return ResourceTrackingDto(
      viewedIds: _stringList(json['viewed_ids']),
      completedIds: _stringList(json['completed_ids']),
    );
  }

  final List<String> viewedIds;
  final List<String> completedIds;

  Map<String, dynamic> toJson() => {
        'viewed_ids': viewedIds,
        'completed_ids': completedIds,
      };

  ResourceTracking toDomain() {
    return ResourceTracking(
      viewedIds: viewedIds.toSet(),
      completedIds: completedIds.toSet(),
    );
  }

  static List<String> _stringList(Object? value) {
    if (value is! List || value.any((item) => item is! String)) {
      return const [];
    }
    return value.cast<String>().where((item) => item.trim().isNotEmpty).toList();
  }
}
