import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@lazySingleton
class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  Future<void> remove(String key) async => await _prefs.remove(key);

  Future<void> saveModelList<T>({
    required String key,
    required List<T> items,
    required Map<String, dynamic> Function(T) toJson,
  }) async {
    final String encodedData = jsonEncode(items.map((item) => toJson(item)).toList());
    await _prefs.setString(key, encodedData);
  }

  List<T> getModelList<T>({required String key, required T Function(Map<String, dynamic>) fromJson}) {
    final String? data = _prefs.getString(key);
    if (data == null || data.isEmpty) return [];

    try {
      final List<dynamic> decodedData = jsonDecode(data);
      return decodedData.map((item) => fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveImages(String key, List<String> imagePaths) async {
    await _prefs.setStringList(key, imagePaths);
  }

  List<String> getImages(String key) {
    return _prefs.getStringList(key) ?? [];
  }

  Future<void> saveBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  bool getBool(String key, {bool defaultValue = false}) {
    return _prefs.getBool(key) ?? defaultValue;
  }
}
