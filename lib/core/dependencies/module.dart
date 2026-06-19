import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@module
abstract class InjectionModule {
  @preResolve
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();

  @lazySingleton
  Dio get dio {
    return Dio(
      BaseOptions(
        baseUrl: 'https://api.wineapi.io',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'X-API-Key': 'wapi_b78ebb7bb03ea81a327806b64ecc4f455f0ec45505d0e810ac7b9fb2c2c60908'},
      ),
    );
  }
}
