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
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'X-API-Key': 'wapi_7be61e7336998c2d4b58e3abdc885117a210c86c392ecba939f53cf31f8377c4'},
      ),
    );
  }
}
