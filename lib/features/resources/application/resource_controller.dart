import 'package:flutter/foundation.dart';
import 'package:mision_admision/domain/models/resource_card.dart';
import 'package:mision_admision/domain/models/resource_tracking.dart';
import 'package:mision_admision/domain/models/resource_type.dart';
import 'package:mision_admision/domain/repositories/resource_repository.dart';
import 'package:mision_admision/domain/repositories/resource_tracking_repository.dart';
import 'package:mision_admision/features/resources/application/resource_state.dart';

class ResourceController extends ChangeNotifier {
  ResourceController({
    required ResourceRepository resourceRepository,
    required ResourceTrackingRepository trackingRepository,
  })  : _resourceRepository = resourceRepository,
        _trackingRepository = trackingRepository;

  final ResourceRepository _resourceRepository;
  final ResourceTrackingRepository _trackingRepository;

  ResourceState _state = ResourceState.loading();
  ResourceState get state => _state;

  Future<void> start() async {
    _setState(ResourceState.loading());
    try {
      final results = await Future.wait<Object>([
        _resourceRepository.loadResources(),
        _trackingRepository.load(),
      ]);
      _setState(
        ResourceState.ready(
          resources: results[0] as List<ResourceCard>,
          tracking: results[1] as ResourceTracking,
        ),
      );
    } on Object catch (error) {
      _setState(ResourceState.failure(
        'No fue posible cargar los recursos. ${error.toString()}',
      ));
    }
  }

  void selectType(ResourceType? type) {
    if (_state.phase != ResourcePhase.ready) return;
    _setState(ResourceState.ready(
      resources: _state.resources,
      tracking: _state.tracking,
      selectedType: type,
      selectedTag: _state.selectedTag,
    ));
  }

  void selectTag(String? tag) {
    if (_state.phase != ResourcePhase.ready) return;
    _setState(ResourceState.ready(
      resources: _state.resources,
      tracking: _state.tracking,
      selectedType: _state.selectedType,
      selectedTag: tag,
    ));
  }

  Future<void> markViewed(String id) async {
    if (_state.phase != ResourcePhase.ready || _state.tracking.isViewed(id)) {
      return;
    }
    await _updateTracking(_state.tracking.markViewed(id));
  }

  Future<void> toggleCompleted(String id) async {
    if (_state.phase != ResourcePhase.ready) return;
    await _updateTracking(_state.tracking.toggleCompleted(id));
  }

  Future<void> _updateTracking(ResourceTracking tracking) async {
    _setState(ResourceState.ready(
      resources: _state.resources,
      tracking: tracking,
      selectedType: _state.selectedType,
      selectedTag: _state.selectedTag,
    ));
    await _trackingRepository.save(tracking);
  }

  void _setState(ResourceState value) {
    _state = value;
    notifyListeners();
  }
}
