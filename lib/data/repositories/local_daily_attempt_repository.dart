import 'dart:convert';

import 'package:mision_admision/core/storage/json_key_value_store.dart';
import 'package:mision_admision/core/storage/storage_keys.dart';
import 'package:mision_admision/data/dto/daily_attempt_dto.dart';
import 'package:mision_admision/domain/models/daily_attempt.dart';
import 'package:mision_admision/domain/repositories/daily_attempt_repository.dart';

class LocalDailyAttemptRepository implements DailyAttemptRepository {
  const LocalDailyAttemptRepository({required this.store});

  final JsonKeyValueStore store;

  @override
  Future<void> clear() => store.remove(StorageKeys.dailyAttempt);

  @override
  Future<DailyAttempt?> load() async {
    final raw = await store.read(StorageKeys.dailyAttempt);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('El intento local debe ser un objeto JSON.');
      }
      return DailyAttemptDto.fromJson(decoded).toDomain();
    } on Object {
      await clear();
      return null;
    }
  }

  @override
  Future<void> save(DailyAttempt attempt) {
    final encoded = jsonEncode(DailyAttemptDto.fromDomain(attempt).toJson());
    return store.write(StorageKeys.dailyAttempt, encoded);
  }
}
