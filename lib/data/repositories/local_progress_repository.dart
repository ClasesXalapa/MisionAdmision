import 'dart:convert';

import 'package:mision_admision/core/storage/json_key_value_store.dart';
import 'package:mision_admision/core/storage/storage_keys.dart';
import 'package:mision_admision/data/dto/learner_progress_dto.dart';
import 'package:mision_admision/domain/models/learner_progress.dart';
import 'package:mision_admision/domain/repositories/progress_repository.dart';

typedef ProgressMirrorCallback = Future<void> Function(
  LearnerProgress progress,
);

class LocalProgressRepository implements ProgressRepository {
  LocalProgressRepository({
    required this.store,
    this.onProgressChanged,
  });

  final JsonKeyValueStore store;
  final ProgressMirrorCallback? onProgressChanged;

  @override
  Future<LearnerProgress> load() async {
    final raw = await store.read(StorageKeys.learnerProgress);
    if (raw == null || raw.isEmpty) {
      const progress = LearnerProgress();
      await _mirror(progress);
      return progress;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('El progreso debe ser un objeto JSON.');
      }
      final progress = LearnerProgressDto.fromJson(decoded).toDomain();
      await _mirror(progress);
      return progress;
    } on Object {
      await store.remove(StorageKeys.learnerProgress);
      const progress = LearnerProgress();
      await _mirror(progress);
      return progress;
    }
  }

  @override
  Future<void> save(LearnerProgress progress) async {
    final encoded = jsonEncode(LearnerProgressDto.fromDomain(progress).toJson());
    await store.write(StorageKeys.learnerProgress, encoded);
    await _mirror(progress);
  }

  Future<void> _mirror(LearnerProgress progress) async {
    final callback = onProgressChanged;
    if (callback == null) return;
    try {
      await callback(progress);
    } on Object {
      // El espejo de notificaciones es auxiliar. Nunca debe impedir que el
      // progreso educativo se lea o se guarde correctamente.
    }
  }
}
