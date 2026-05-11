import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:home_wine/feature/wine/data/models/wine_model.dart';
import 'package:injectable/injectable.dart';

abstract class WineRepository {
  Future<List<WineModel>> searchWines({String query = '', int limit = 20, int offset = 0});
  Future<WineModel> getWineDetails(String id);
}

@Injectable(as: WineRepository)
class WineRepositoryImpl implements WineRepository {
  final Dio _dio;
  WineRepositoryImpl(this._dio);

  @override
  Future<List<WineModel>> searchWines({String query = '', int limit = 20, int offset = 0}) async {
    try {
      final response = await _dio.get(
        '/wines/search',
        queryParameters: {'q': query, 'limit': limit, 'offset': offset},
      );
      log('Ответ от API: ${response.data}');
      final List results = response.data['results'] ?? [];
      return results.map((json) => WineModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Ошибка поиска: $e');
    }
  }

  @override
  Future<WineModel> getWineDetails(String id) async {
    try {
      final response = await _dio.get('/wines/$id');
      log('Детали вина (ID: $id): ${response.data}');
      return WineModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Ошибка загрузки деталей: $e');
    }
  }
}
