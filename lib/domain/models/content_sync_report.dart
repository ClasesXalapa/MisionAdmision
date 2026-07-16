import 'package:mision_admision/domain/models/content_cache_metadata.dart';
import 'package:mision_admision/domain/models/content_file_kind.dart';

enum ContentFileSyncOutcome { updated, unchanged, failed }

class ContentFileSyncResult {
  const ContentFileSyncResult({
    required this.kind,
    required this.outcome,
    required this.version,
    this.message,
  });

  final ContentFileKind kind;
  final ContentFileSyncOutcome outcome;
  final String version;
  final String? message;
}

class ContentSyncReport {
  ContentSyncReport({
    required this.metadata,
    List<ContentFileSyncResult> files = const [],
  }) : files = List.unmodifiable(files);

  final ContentCacheMetadata metadata;
  final List<ContentFileSyncResult> files;

  bool get changed =>
      files.any((result) => result.outcome == ContentFileSyncOutcome.updated);

  bool get hasFailures =>
      files.any((result) => result.outcome == ContentFileSyncOutcome.failed);
}
