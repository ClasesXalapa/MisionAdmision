import 'package:mision_admision/domain/models/resource_tracking.dart';

abstract interface class ResourceTrackingRepository {
  Future<ResourceTracking> load();

  Future<void> save(ResourceTracking tracking);
}
