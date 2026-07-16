import 'package:mision_admision/domain/models/resource_card.dart';
import 'package:mision_admision/domain/models/resource_tracking.dart';
import 'package:mision_admision/domain/models/resource_type.dart';

class ResourceState {
  ResourceState({
    required this.phase,
    List<ResourceCard> resources = const [],
    ResourceTracking? tracking,
    this.selectedType,
    this.selectedTag,
    this.errorMessage,
  })  : resources = List.unmodifiable(resources),
        tracking = tracking ?? ResourceTracking();

  factory ResourceState.loading() => ResourceState(phase: ResourcePhase.loading);

  factory ResourceState.ready({
    required List<ResourceCard> resources,
    required ResourceTracking tracking,
    ResourceType? selectedType,
    String? selectedTag,
  }) {
    return ResourceState(
      phase: ResourcePhase.ready,
      resources: resources,
      tracking: tracking,
      selectedType: selectedType,
      selectedTag: selectedTag,
    );
  }

  factory ResourceState.failure(String message) {
    return ResourceState(
      phase: ResourcePhase.failure,
      errorMessage: message,
    );
  }

  final ResourcePhase phase;
  final List<ResourceCard> resources;
  final ResourceTracking tracking;
  final ResourceType? selectedType;
  final String? selectedTag;
  final String? errorMessage;

  List<ResourceCard> get filteredResources {
    return resources.where((resource) {
      final matchesType = selectedType == null || resource.type == selectedType;
      final matchesTag = selectedTag == null || resource.tags.contains(selectedTag);
      return matchesType && matchesTag;
    }).toList(growable: false);
  }

  List<String> get availableTags {
    final tags = resources.expand((resource) => resource.tags).toSet().toList()..sort();
    return tags;
  }
}

enum ResourcePhase { loading, ready, failure }
