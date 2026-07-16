import 'dart:convert';

import 'package:mision_admision/core/storage/json_key_value_store.dart';
import 'package:mision_admision/core/storage/storage_keys.dart';
import 'package:mision_admision/data/dto/resource_tracking_dto.dart';
import 'package:mision_admision/domain/models/resource_tracking.dart';
import 'package:mision_admision/domain/repositories/resource_tracking_repository.dart';

class LocalResourceTrackingRepository implements ResourceTrackingRepository {
  const LocalResourceTrackingRepository({required this.store});

  final JsonKeyValueStore store;

  @override
  Future<ResourceTracking> load() async {
    final raw = await store.read(StorageKeys.resourceTracking);
    if (raw == null || raw.isEmpty) {
      return ResourceTracking();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('El seguimiento debe ser un objeto JSON.');
      }
      return ResourceTrackingDto.fromJson(decoded).toDomain();
    } on Object {
      await store.remove(StorageKeys.resourceTracking);
      return ResourceTracking();
    }
  }

  @override
  Future<void> save(ResourceTracking tracking) {
    final raw = jsonEncode(ResourceTrackingDto.fromDomain(tracking).toJson());
    return store.write(StorageKeys.resourceTracking, raw);
  }
}
