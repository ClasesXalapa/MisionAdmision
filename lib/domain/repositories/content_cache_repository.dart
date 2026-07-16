import 'package:mision_admision/domain/models/content_cache_metadata.dart';
import 'package:mision_admision/domain/models/content_file_kind.dart';

abstract interface class ContentCacheRepository {
  Future<String?> readRaw(ContentFileKind kind);

  Future<void> writeRaw(
    ContentFileKind kind,
    String version,
    String raw,
  );

  Future<void> discard(ContentFileKind kind);

  Future<void> discardVersion(ContentFileKind kind, String version);

  Future<ContentCacheMetadata> loadMetadata();

  Future<void> saveMetadata(ContentCacheMetadata metadata);
}
