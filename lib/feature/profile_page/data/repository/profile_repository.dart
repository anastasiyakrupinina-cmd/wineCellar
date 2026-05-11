import 'dart:convert';

import 'package:home_wine/core/database/database_service.dart';
import 'package:home_wine/core/sync/ucloud_sync_service.dart';
import 'package:home_wine/feature/profile_page/data/repository/storage_model.dart';
import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';

abstract class ProfileRepository {
  Future<void> signOut();
  Future<String?> getCurrentUsername();
  Future<void> saveCabinet(CabinetModel cabinet);
  Future<List<CabinetModel>> getStorageLocations();
  Future<void> deleteCabinet(String cabinetId);
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
  Future<void> signOut() async {
    await _syncService.signOut();
  }

  @override
  Future<String?> getCurrentUsername() async {
    return _syncService.getCurrentUsername();
  }

  @override
  Future<void> saveCabinet(CabinetModel cabinet) async {
    _assertInitialized();
    await _databaseService.db.insert(
      'cabinets',
      {
        'id': cabinet.id,
        'data': jsonEncode(cabinet.toJson()),
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _syncService.syncOnClose(); // fire-and-forget
  }

  @override
  Future<List<CabinetModel>> getStorageLocations() async {
    _assertInitialized();
    final rows = await _databaseService.db.query('cabinets');
    return rows.map((row) {
      final json = jsonDecode(row['data'] as String) as Map<String, dynamic>;
      return CabinetModel.fromJson(json);
    }).toList();
  }

  @override
  Future<void> deleteCabinet(String cabinetId) async {
    _assertInitialized();
    await _databaseService.db.delete('cabinets', where: 'id = ?', whereArgs: [cabinetId]);
    _syncService.syncOnClose(); // fire-and-forget
  }
}
