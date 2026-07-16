import 'dart:convert';

import 'package:mision_admision/core/storage/json_key_value_store.dart';
import 'package:mision_admision/core/storage/storage_keys.dart';
import 'package:mision_admision/data/dto/learner_progress_dto.dart';
import 'package:mision_admision/domain/models/learner_progress.dart';
import 'package:mision_admision/domain/repositories/progress_repository.dart';

class LocalProgressRepository implements ProgressRepository {
  const LocalProgressRepository({required this.store});

  final JsonKeyValueStore store;

  @override
  Future<LearnerProgress> load() async {
    final raw = await store.read(StorageKeys.learnerProgress);
    if (raw == null || raw.isEmpty) {
      return const LearnerProgress();
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('El progreso debe ser un objeto JSON.');
      }
      return LearnerProgressDto.fromJson(decoded).toDomain();
    } on Object {
      await store.remove(StorageKeys.learnerProgress);
      return const LearnerProgress();
    }
  }

  @override
  Future<void> save(LearnerProgress progress) {
    final encoded = jsonEncode(LearnerProgressDto.fromDomain(progress).toJson());
    return store.write(StorageKeys.learnerProgress, encoded);
  }
}
