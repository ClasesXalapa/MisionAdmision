import 'package:mision_admision/domain/models/content_file_kind.dart';

enum ContentSyncOutcome { never, success, partial, failed }

class ContentCacheMetadata {
  ContentCacheMetadata({
    this.schemaVersion = 1,
    this.contentVersion,
    this.lastAttemptAt,
    this.lastSuccessAt,
    this.lastOutcome = ContentSyncOutcome.never,
    this.message,
    Map<ContentFileKind, String> fileVersions = const {},
  }) : fileVersions = Map.unmodifiable(fileVersions);

  final int schemaVersion;
  final String? contentVersion;
  final DateTime? lastAttemptAt;
  final DateTime? lastSuccessAt;
  final ContentSyncOutcome lastOutcome;
  final String? message;
  final Map<ContentFileKind, String> fileVersions;

  String? versionFor(ContentFileKind kind) => fileVersions[kind];

  ContentCacheMetadata copyWith({
    String? contentVersion,
    bool clearContentVersion = false,
    DateTime? lastAttemptAt,
    DateTime? lastSuccessAt,
    bool clearLastSuccessAt = false,
    ContentSyncOutcome? lastOutcome,
    String? message,
    bool clearMessage = false,
    Map<ContentFileKind, String>? fileVersions,
  }) {
    return ContentCacheMetadata(
      schemaVersion: schemaVersion,
      contentVersion:
          clearContentVersion ? null : contentVersion ?? this.contentVersion,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      lastSuccessAt:
          clearLastSuccessAt ? null : lastSuccessAt ?? this.lastSuccessAt,
      lastOutcome: lastOutcome ?? this.lastOutcome,
      message: clearMessage ? null : message ?? this.message,
      fileVersions: fileVersions ?? this.fileVersions,
    );
  }
}
