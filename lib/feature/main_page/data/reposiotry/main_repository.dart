import 'dart:convert';

import 'package:home_wine/core/database/database_service.dart';
import 'package:home_wine/core/sync/ucloud_sync_service.dart';
import 'package:home_wine/feature/wine/data/models/wine_model.dart';
import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';

abstract class MainRepository {
  Future<void> saveWine(WineModel wine);
  Future<List<WineModel>> getLocalWines();
  Future<List<WineModel>> getRemoteWines();
  Future<void> deleteWine(String wineId);
}

@Injectable(as: MainRepository)
class MainRepositoryImpl implements MainRepository {
  final DatabaseService _databaseService;
  final UCloudSyncService _syncService;

  MainRepositoryImpl(this._databaseService, this._syncService);

  void _assertInitialized() {
    if (!_databaseService.isInitialized) {
      throw StateError('DatabaseService not initialized. Call init() first.');
    }
  }

  @override
  Future<void> saveWine(WineModel wine) async {
    _assertInitialized();
    await _databaseService.db.insert(
      'wines',
      {
        'id': wine.id,
        'name': wine.name,
        'vintage': wine.vintage,
        'type': wine.type,
        'winery': wine.winery,
        'region': wine.region,
        'country': wine.country,
        'averageRating': wine.averageRating,
        'ratingsCount': wine.ratingsCount,
        'description': wine.description,
        'alcoholContent': wine.alcoholContent,
        'quantity': wine.quantity,
        'cellarLocation': wine.cellarLocation,
        'notice': wine.notice,
        'imageUrl': wine.imageUrl,
        'prices': wine.prices != null
            ? jsonEncode(wine.prices!.map((p) => p.toJson()).toList())
            : null,
        'pairings': wine.foodPairings != null
            ? jsonEncode(wine.foodPairings!.map((f) => {'food': f}).toList())
            : null,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _syncService.syncOnClose(); // fire-and-forget: upload while app is still active
  }

  @override
  Future<List<WineModel>> getLocalWines() async {
    _assertInitialized();
    final rows = await _databaseService.db.query('wines', orderBy: 'name ASC');
    return rows.map(_rowToWineModel).toList();
  }

  /// SQLite is the source of truth — delegates to getLocalWines().
  @override
  Future<List<WineModel>> getRemoteWines() async {
    return getLocalWines();
  }

  @override
  Future<void> deleteWine(String wineId) async {
    _assertInitialized();
    await _databaseService.db.delete('wines', where: 'id = ?', whereArgs: [wineId]);
    _syncService.syncOnClose(); // fire-and-forget
  }

  WineModel _rowToWineModel(Map<String, dynamic> row) {
    return WineModel.fromJson({
      'id': row['id'],
      'name': row['name'],
      'vintage': row['vintage'],
      'type': row['type'],
      'winery': row['winery'],
      'region': row['region'],
      'country': row['country'],
      'averageRating': row['averageRating'],
      'ratingsCount': row['ratingsCount'],
      'description': row['description'],
      'alcoholContent': row['alcoholContent'],
      'quantity': row['quantity'],
      'cellarLocation': row['cellarLocation'],
      'notice': row['notice'],
      'imageUrl': row['imageUrl'],
      'prices': row['prices'] != null ? jsonDecode(row['prices'] as String) : null,
      'pairings': row['pairings'] != null ? jsonDecode(row['pairings'] as String) : null,
    });
  }
}
