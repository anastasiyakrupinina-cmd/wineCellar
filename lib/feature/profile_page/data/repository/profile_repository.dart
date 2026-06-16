import 'package:wine_cellar/core/database/database_service.dart';
import 'package:wine_cellar/core/sync/ucloud_sync_service.dart';
import 'package:wine_cellar/feature/profile_page/data/repository/storage_model.dart';
import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';

abstract class ProfileRepository {
  Future<void> signOut();
  Future<String?> getCurrentUsername();
  Future<void> saveCabinet(CabinetModel cabinet);
  Future<List<CabinetModel>> getStorageLocations();
  Future<void> deleteCabinet(String cabinetId);

  Future<List<String>> getWineIdsInCabinet(String cabinetId);

  /// Frees the [count] highest-indexed spots occupied by [wineId].
  Future<void> freeSpots(String wineId, int count);

  /// Returns all positions currently occupied by [wineId], with human-readable labels.
  Future<List<OccupiedSpot>> getOccupiedSpots(String wineId);
}

@Injectable(as: ProfileRepository)
class ProfileRepositoryImpl implements ProfileRepository {
  final DatabaseService _databaseService;
  final UCloudSyncService _syncService;

  ProfileRepositoryImpl(this._databaseService, this._syncService);

  void _assertInitialized() {
    if (!_databaseService.isInitialized) {
      throw StateError('DatabaseService not initialized. Call init() first.');
    }
  }

  @override
  Future<void> signOut() async => _syncService.signOut();

  @override
  Future<String?> getCurrentUsername() async => _syncService.getCurrentUsername();

  @override
  Future<void> saveCabinet(CabinetModel cabinet) async {
    _assertInitialized();
    await _databaseService.db.transaction((txn) async {
      await txn.insert(
        'cabinets',
        {'id': cabinet.id, 'name': cabinet.name},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await txn.delete('shelves', where: 'cabinet_id = ?', whereArgs: [cabinet.id]);
      for (final shelf in cabinet.shelves) {
        await txn.insert('shelves', {
          'id': shelf.id, 'cabinet_id': cabinet.id, 'name': shelf.name,
        });
        for (final pos in shelf.positions) {
          await txn.insert('positions', {
            'id':             pos.id,
            'shelf_id':       shelf.id,
            'position_index': pos.index,
            'wine_id':        pos.wineId,
            'bottle_size':    pos.bottleSize,
          });
        }
      }
    });
    _syncService.syncAfterWrite();
  }


//into the CabinetModel
  @override
  Future<List<CabinetModel>> getStorageLocations() async {
    _assertInitialized();
    final rows = await _databaseService.db.rawQuery('''
      SELECT c.id   AS cabinet_id,
             c.name AS cabinet_name,
             s.id   AS shelf_id,
             s.name AS shelf_name,
             p.id   AS pos_id,
             p.position_index,
             p.wine_id,
             p.bottle_size
      FROM   cabinets c
      LEFT JOIN shelves   s ON s.cabinet_id = c.id
      LEFT JOIN positions p ON p.shelf_id   = s.id
      ORDER BY c.id, s.id, p.position_index
    ''');

    final cabinetNames   = <String, String>{};
    final cabinetShelves = <String, List<ShelfModel>>{};
    final shelfNames     = <String, String>{};
    final shelfPositions = <String, List<BottlePositionModel>>{};
    final shelfToCabinet = <String, String>{};

    for (final row in rows) {
      final cabinetId = row['cabinet_id'] as String;
      final shelfId   = row['shelf_id']   as String?;

      cabinetNames.putIfAbsent(cabinetId, () => row['cabinet_name'] as String);
      cabinetShelves.putIfAbsent(cabinetId, () => []);

      if (shelfId == null) continue;

      shelfNames.putIfAbsent(shelfId, () => row['shelf_name'] as String);
      shelfToCabinet.putIfAbsent(shelfId, () => cabinetId);
      shelfPositions.putIfAbsent(shelfId, () => []);

      if (row['pos_id'] == null) continue;

      shelfPositions[shelfId]!.add(BottlePositionModel(
        id:         row['pos_id'] as String,
        index:      row['position_index'] as int,
        wineId:     row['wine_id'] as String?,
        bottleSize: row['bottle_size'] as String?,
      ));
    }

    for (final entry in shelfNames.entries) {
      final shelfId   = entry.key;
      final cabinetId = shelfToCabinet[shelfId]!;
      cabinetShelves[cabinetId]!.add(ShelfModel(
        id:        shelfId,
        name:      entry.value,
        positions: shelfPositions[shelfId] ?? [],
      ));
    }

    return cabinetNames.entries.map((e) => CabinetModel(
      id:      e.key,
      name:    e.value,
      shelves: cabinetShelves[e.key] ?? [],
    )).toList();
  }

  @override
  Future<void> deleteCabinet(String cabinetId) async {
    _assertInitialized();
    await _databaseService.db.delete(
      'cabinets', where: 'id = ?', whereArgs: [cabinetId],
    );
    _syncService.syncAfterWrite();
  }

  @override
  Future<List<String>> getWineIdsInCabinet(String cabinetId) async {
    _assertInitialized();
    final rows = await _databaseService.db.rawQuery('''
      SELECT DISTINCT p.wine_id
      FROM   positions p
      JOIN   shelves   s ON p.shelf_id = s.id
      WHERE  s.cabinet_id = ? AND p.wine_id IS NOT NULL
    ''', [cabinetId]);
    return rows.map((r) => r['wine_id'] as String).toList();
  }

  @override
  Future<void> freeSpots(String wineId, int count) async {
    _assertInitialized();
    final db = _databaseService.db;

    final toFree = await db.rawQuery('''
      SELECT id FROM positions
      WHERE  wine_id = ?
      ORDER  BY position_index DESC
      LIMIT  ?
    ''', [wineId, count]);

    if (toFree.isEmpty) return;

    final ids          = toFree.map((r) => r['id'] as String).toList();
    final placeholders = List.filled(ids.length, '?').join(', ');
    await db.rawUpdate(
      'UPDATE positions SET wine_id = NULL WHERE id IN ($placeholders)',
      ids,
    );
  }

  @override
  Future<List<OccupiedSpot>> getOccupiedSpots(String wineId) async {
    _assertInitialized();
    final rows = await _databaseService.db.rawQuery('''
      SELECT p.id AS position_id,
             c.name AS cabinet_name,
             s.name AS shelf_name,
             p.position_index,
             p.bottle_size
      FROM   positions p
      JOIN   shelves s   ON p.shelf_id   = s.id
      JOIN   cabinets c  ON s.cabinet_id = c.id
      WHERE  p.wine_id = ?
      ORDER  BY c.name, s.name, p.position_index
    ''', [wineId]);
    return rows.map((row) => OccupiedSpot(
      positionId: row['position_id'] as String,
      label: '${row['cabinet_name']} > ${row['shelf_name']} > Spot ${row['position_index']}',
      bottleSize: row['bottle_size'] as String?,
    )).toList();
  }

}
