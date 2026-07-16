import 'package:flutter/services.dart';

abstract interface class AssetTextLoader {
  Future<String> load(String path);
}

class RootBundleAssetTextLoader implements AssetTextLoader {
  const RootBundleAssetTextLoader();

  @override
  Future<String> load(String path) => rootBundle.loadString(path);
}
