import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mision_admision/app/dependencies.dart';
import 'package:mision_admision/domain/models/content_cache_metadata.dart';

final contentCacheMetadataProvider =
    FutureProvider.autoDispose<ContentCacheMetadata>((ref) {
  return ref.read(contentCacheRepositoryProvider).loadMetadata();
});
