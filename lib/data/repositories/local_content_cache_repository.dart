import 'dart:convert';

import 'package:mision_admision/core/storage/json_key_value_store.dart';
import 'package:mision_admision/core/storage/storage_keys.dart';
import 'package:mision_admision/domain/models/content_cache_metadata.dart';
import 'package:mision_admision/domain/models/content_file_kind.dart';
import 'package:mision_admision/domain/repositories/content_cache_repository.dart';

class LocalContentCacheRepository implements ContentCacheRepository {
  LocalContentCacheRepository({required JsonKeyValueStore store}) : _store = store;

  final JsonKeyValueStore _store;

  @override
  Future<String?> readRaw(ContentFileKind kind) async {
    final version = (await loadMetadata()).versionFor(kind);
    if (version == null) return null;
    return _store.read(_versionedKey(kind, version));
  }

  @override
  Future<void> writeRaw(
    ContentFileKind kind,
    String version,
    String raw,
  ) {
    return _store.write(_versionedKey(kind, version), raw);
  }

  @override
  Future<void> discard(ContentFileKind kind) async {
    final metadata = await loadMetadata();
    final version = metadata.versionFor(kind);
    if (version != null) {
      await discardVersion(kind, version);
    }
    final versions = Map<ContentFileKind, String>.of(metadata.fileVersions)
      ..remove(kind);
    await saveMetadata(metadata.copyWith(fileVersions: versions));
  }

  @override
  Future<void> discardVersion(ContentFileKind kind, String version) {
    return _store.remove(_versionedKey(kind, version));
  }

  @override
  Future<ContentCacheMetadata> loadMetadata() async {
    final raw = await _store.read(StorageKeys.contentCacheMetadata);
    if (raw == null || raw.trim().isEmpty) {
      return ContentCacheMetadata();
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) throw const FormatException();
      final json = Map<String, dynamic>.from(decoded);
      final rawVersions = json['file_versions'];
      final versions = <ContentFileKind, String>{};
      if (rawVersions is Map) {
        for (final entry in rawVersions.entries) {
          if (entry.key is! String || entry.value is! String) continue;
          final kind = ContentFileKind.tryParse(entry.key as String);
          final version = (entry.value as String).trim();
          if (kind != null && version.isNotEmpty) versions[kind] = version;
        }
      }

      return ContentCacheMetadata(
        schemaVersion: json['schema_version'] is int
            ? json['schema_version'] as int
            : 1,
        contentVersion: _nullableString(json['content_version']),
        lastAttemptAt: _nullableDate(json['last_attempt_at']),
        lastSuccessAt: _nullableDate(json['last_success_at']),
        lastOutcome: _parseOutcome(json['last_outcome']),
        message: _nullableString(json['message']),
        fileVersions: versions,
      );
    } on Object {
      await _store.remove(StorageKeys.contentCacheMetadata);
      return ContentCacheMetadata();
    }
  }

  @override
  Future<void> saveMetadata(ContentCacheMetadata metadata) async {
    final json = <String, dynamic>{
      'schema_version': metadata.schemaVersion,
      'content_version': metadata.contentVersion,
      'last_attempt_at': metadata.lastAttemptAt?.toIso8601String(),
      'last_success_at': metadata.lastSuccessAt?.toIso8601String(),
      'last_outcome': metadata.lastOutcome.name,
      'message': metadata.message,
      'file_versions': {
        for (final entry in metadata.fileVersions.entries)
          entry.key.key: entry.value,
      },
    };
    await _store.write(StorageKeys.contentCacheMetadata, jsonEncode(json));
  }

  String _versionedKey(ContentFileKind kind, String version) {
    return '${_baseKeyFor(kind)}.${Uri.encodeComponent(version)}';
  }

  String _baseKeyFor(ContentFileKind kind) => switch (kind) {
        ContentFileKind.questions => StorageKeys.contentQuestions,
        ContentFileKind.challenges => StorageKeys.contentChallenges,
        ContentFileKind.resources => StorageKeys.contentResources,
        ContentFileKind.ranks => StorageKeys.contentRanks,
      };

  String? _nullableString(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value.trim();
  }

  DateTime? _nullableDate(Object? value) {
    if (value is! String) return null;
    return DateTime.tryParse(value);
  }

  ContentSyncOutcome _parseOutcome(Object? value) {
    if (value is String) {
      for (final outcome in ContentSyncOutcome.values) {
        if (outcome.name == value) return outcome;
      }
    }
    return ContentSyncOutcome.never;
  }
}
