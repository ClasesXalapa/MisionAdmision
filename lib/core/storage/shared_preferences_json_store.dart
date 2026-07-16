import 'package:mision_admision/core/storage/json_key_value_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesJsonStore implements JsonKeyValueStore {
  SharedPreferencesJsonStore({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> read(String key) => _preferences.getString(key);

  @override
  Future<void> remove(String key) => _preferences.remove(key);

  @override
  Future<void> write(String key, String value) async {
    await _preferences.setString(key, value);
  }
}
