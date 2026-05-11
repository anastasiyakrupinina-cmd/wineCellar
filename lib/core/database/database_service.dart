import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

@lazySingleton
class DatabaseService {
  Database? _db;
  String? _dbPath;

  /// True once init() has completed successfully.
  bool get isInitialized => _db != null;

  /// Returns the open database. Throws if init() was not called first.
  Database get db {
    if (_db == null) {
      throw StateError('DatabaseService not initialized. Call init() first.');
    }
    return _db!;
  }

  /// Returns the on-disk path to the .db file.
  /// Remains valid after close() so that UCloudSyncService can still reference it.
  String get dbPath {
    if (_dbPath == null) {
      throw StateError('DatabaseService not initialized. Call init() first.');
    }
    return _dbPath!;
  }

  /// Opens (or creates) the SQLite database.
  /// Safe to call multiple times — returns immediately if already open.
  /// No-op on web.
  Future<void> init() async {
    if (_db != null) return; // already open — idempotent
    if (kIsWeb) return;      // SQLite not supported on web

    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      final dir = await getApplicationDocumentsDirectory();
      _dbPath = p.join(dir.path, 'winecellar.db');
    } else {
      final dbDir = await getDatabasesPath();
      _dbPath = p.join(dbDir, 'winecellar.db');
    }

    _db = await openDatabase(
      _dbPath!,
      version: 1,
      onCreate: _onCreate,
    );
  }

  /// Closes the database connection without clearing the path.
  /// Used by UCloudSyncService before overwriting the file on disk.
  Future<void> close() async {
    await _db?.close();
    _db = null;
    // _dbPath is intentionally preserved so dbPath still works after close()
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE wines (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        vintage INTEGER,
        type TEXT,
        winery TEXT,
        region TEXT,
        country TEXT,
        averageRating REAL,
        ratingsCount INTEGER,
        description TEXT,
        alcoholContent TEXT,
        quantity INTEGER DEFAULT 1,
        cellarLocation TEXT,
        notice TEXT,
        imageUrl TEXT,
        prices TEXT,
        pairings TEXT,
        updatedAt INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE cabinets (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        updatedAt INTEGER
      )
    ''');
  }
}
