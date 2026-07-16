import 'package:mision_admision/core/assets/asset_text_loader.dart';
import 'package:mision_admision/domain/models/content_file_kind.dart';
import 'package:mision_admision/domain/repositories/content_cache_repository.dart';

class LocalFirstContentLoader {
  const LocalFirstContentLoader({
    required ContentCacheRepository cache,
    required AssetTextLoader assets,
  })  : _cache = cache,
        _assets = assets;

  final ContentCacheRepository _cache;
  final AssetTextLoader _assets;

  Future<T> load<T>({
    required ContentFileKind kind,
    required String fallbackAssetPath,
    required T Function(String raw) parse,
  }) async {
    final cached = await _cache.readRaw(kind);
    if (cached != null && cached.trim().isNotEmpty) {
      try {
        return parse(cached);
      } on Object {
        await _cache.discard(kind);
      }
    }

    final fallback = await _assets.load(fallbackAssetPath);
    return parse(fallback);
  }

  Future<String> loadRaw({
    required ContentFileKind kind,
    required String fallbackAssetPath,
  }) async {
    final cached = await _cache.readRaw(kind);
    if (cached != null && cached.trim().isNotEmpty) return cached;
    return _assets.load(fallbackAssetPath);
  }
}
