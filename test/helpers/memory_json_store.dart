import 'package:mision_admision/core/storage/json_key_value_store.dart';

class MemoryJsonStore implements JsonKeyValueStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}
