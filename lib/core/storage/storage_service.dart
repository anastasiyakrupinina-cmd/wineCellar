import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

//"Cabinet View / List View" toggle in SharedPreferences

@lazySingleton
class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  Future<void> saveBool(String key, bool value) async => _prefs.setBool(key, value);

  bool getBool(String key, {bool defaultValue = false}) => _prefs.getBool(key) ?? defaultValue;
}
