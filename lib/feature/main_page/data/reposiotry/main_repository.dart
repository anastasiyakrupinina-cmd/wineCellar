import 'dart:convert';

import 'package:wine_cellar/core/database/database_service.dart';
import 'package:wine_cellar/core/sync/ucloud_sync_service.dart';
import 'package:wine_cellar/feature/wine/data/models/purchase_record.dart';
import 'package:wine_cellar/feature/wine/data/models/wine_bottle.dart';
import 'package:wine_cellar/feature/wine/data/models/wine_model.dart';
import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';

abstract class MainRepository {
  Future<void> saveWine(WineModel wine);
  Future<List<WineModel>> getLocalWines();
  Future<List<WineModel>> getRemoteWines();
  Future<void> deleteWine(String wineId);

  Future<List<PurchaseRecord>> getPurchaseHistory(String wineId);
  Future<void> savePurchaseRecord(PurchaseRecord record);
  Future<void> deletePurchaseRecord(String recordId);
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
    await _databaseService.db.transaction((txn) async {
      await _upsertAllWines(txn, wine);

      // INSERT IGNORE + UPDATE avoids cascade-deleting wine_bottles children
      await txn.insert(
        'cellar_wines',
        {'wine_id': wine.id, 'quantity': wine.quantity, 'notice': wine.notice},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      await txn.update(
        'cellar_wines',
        {'quantity': wine.quantity, 'notice': wine.notice},
        where: 'wine_id = ?',
        whereArgs: [wine.id],
      );

      if (wine.bottles != null) {
        await txn.delete('wine_bottles', where: 'wine_id = ?', whereArgs: [wine.id]);
        for (final bottle in wine.bottles!) {
          await txn.insert('wine_bottles', bottle.toMap());
        }
      }
    });
    _syncService.syncOnClose();
  }

  Future<void> _upsertAllWines(DatabaseExecutor db, WineModel wine) async {
    final map = <String, dynamic>{
      'id':             wine.id,
      'name':           wine.name,
      'vintage':        wine.vintage,
      'type':           wine.type,
      'winery':         wine.winery,
      'region':         wine.region,
      'country':        wine.country,
      'averageRating':  wine.averageRating,
      'ratingsCount':   wine.ratingsCount,
      'description':    wine.description,
      'alcoholContent': wine.alcoholContent,
      'imageUrl':       wine.imageUrl,
      'prices':  wine.prices != null
          ? jsonEncode(wine.prices!.map((p) => p.toJson()).toList())
          : null,
      'pairings': wine.foodPairings != null
          ? jsonEncode(wine.foodPairings!.map((f) => {'food': f}).toList())
          : null,
      'grapes': wine.grapes != null ? jsonEncode(wine.grapes) : null,
      'scores': wine.scores != null
          ? jsonEncode(wine.scores!.map((s) => s.toJson()).toList())
          : null,
    };
    await db.insert('all_wines', map, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.update('all_wines', map, where: 'id = ?', whereArgs: [wine.id]);
    await _populateLookupTables(db, wine);
  }

  Future<void> _populateLookupTables(DatabaseExecutor db, WineModel wine) async {
    if (wine.winery != null && wine.winery!.isNotEmpty) {
      await db.insert('wineries', {'name': wine.winery}, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    if (wine.type != null && wine.type!.isNotEmpty) {
      await db.insert('wine_types', {'name': wine.type}, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    if (wine.country != null && wine.country!.isNotEmpty) {
      await db.insert('countries', {'name': wine.country}, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    if (wine.grapes != null) {
      for (final grape in wine.grapes!) {
        if (grape.isNotEmpty) {
          await db.insert('grapes', {'name': grape}, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      }
    }
  }

  @override
  Future<List<WineModel>> getLocalWines() async {
    _assertInitialized();
    final db = _databaseService.db;

    final wineRows = await db.rawQuery('''
      SELECT aw.*, cw.quantity, cw.notice
      FROM   all_wines aw
      JOIN   cellar_wines cw ON aw.id = cw.wine_id
      ORDER  BY aw.name ASC
    ''');

    // Load all bottle sizes grouped by wine_id
    final bottleRows = await db.query('wine_bottles');
    final bottlesByWineId = <String, List<WineBottle>>{};
    for (final row in bottleRows) {
      final wineId = row['wine_id'] as String;
      (bottlesByWineId[wineId] ??= []).add(WineBottle.fromMap(Map<String, dynamic>.from(row)));
    }

    // Fetch all assigned positions with their cabinet/shelf names in one query.
    final posRows = await db.rawQuery('''
      SELECT p.wine_id,
             c.name AS cabinet_name,
             s.name AS shelf_name,
             p.position_index
      FROM   positions p
      JOIN   shelves  s ON p.shelf_id   = s.id
      JOIN   cabinets c ON s.cabinet_id = c.id
      WHERE  p.wine_id IS NOT NULL
      ORDER  BY c.name, s.name, p.position_index
    ''');

    // Group indexes by wine → cabinet+shelf key, ORDER BY order.
    final grouped = <String, Map<String, List<int>>>{};
    for (final row in posRows) {
      final wineId = row['wine_id'] as String;
      final key    = '${row['cabinet_name']} > ${row['shelf_name']}';
      (grouped[wineId] ??= {})[key] = [...(grouped[wineId]?[key] ?? []), row['position_index'] as int];
    }

    // Build the same "Cabinet > Shelf > Spot 1, 2" ; "..."
    final locations = grouped.map((wineId, shelfMap) {
      final parts = shelfMap.entries
          .map((e) => '${e.key} > Spot ${e.value.join(', ')}')
          .toList()
        ..sort();
      return MapEntry(wineId, parts.join(' ; '));
    });

    return wineRows.map((row) {
      final wineId = row['id'] as String;
      var loc = locations[wineId];
      if (loc != null) {
        final assignedCount = grouped[wineId]
                ?.values
                .fold<int>(0, (sum, spots) => sum + spots.length) ??
            0;
        final quantity = (row['quantity'] as int?) ?? 1;
        if (assignedCount < quantity) loc = '$loc ; Unassigned';
      }
      return _rowToWineModel(row, loc, bottlesByWineId[wineId]);
    }).toList();
  }

  @override
  Future<List<WineModel>> getRemoteWines() => getLocalWines();

  @override
  Future<void> deleteWine(String wineId) async {
    _assertInitialized();
    final db = _databaseService.db;

    await db.insert(
      'archive',
      {'wine_id': wineId, 'archived_at': DateTime.now().millisecondsSinceEpoch},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await db.rawUpdate('UPDATE positions SET wine_id = NULL WHERE wine_id = ?', [wineId]);
    await db.delete('cellar_wines', where: 'wine_id = ?', whereArgs: [wineId]);

    _syncService.syncOnClose();
  }

  @override
  Future<List<PurchaseRecord>> getPurchaseHistory(String wineId) async {
    _assertInitialized();
    final rows = await _databaseService.db.query(
      'purchase_history',
      where: 'wine_id = ?',
      whereArgs: [wineId],
      orderBy: 'purchased_at DESC',
    );
    return rows.map((r) => PurchaseRecord.fromMap(Map<String, dynamic>.from(r))).toList();
  }

  @override
  Future<void> savePurchaseRecord(PurchaseRecord record) async {
    _assertInitialized();
    await _databaseService.db.insert(
      'purchase_history',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    if (record.shopName != null && record.shopName!.isNotEmpty) {
      await _databaseService.db.insert(
        'shops',
        {'name': record.shopName},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    _syncService.syncOnClose();
  }

  @override
  Future<void> deletePurchaseRecord(String recordId) async {
    _assertInitialized();
    await _databaseService.db.delete('purchase_history', where: 'id = ?', whereArgs: [recordId]);
    _syncService.syncOnClose();
  }

  WineModel _rowToWineModel(Map<String, dynamic> row, [String? cellarLocation, List<WineBottle>? bottles]) {
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
      'cellarLocation': cellarLocation,
      'notice': row['notice'],
      'imageUrl': row['imageUrl'],
      'prices': row['prices'] != null ? jsonDecode(row['prices'] as String) : null,
      'pairings': row['pairings'] != null ? jsonDecode(row['pairings'] as String) : null,
      'grapes': row['grapes'] != null ? jsonDecode(row['grapes'] as String) : null,
      'scores': row['scores'] != null ? jsonDecode(row['scores'] as String) : null,
    }).copyWith(bottles: bottles);
  }
}
