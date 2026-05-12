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

  bool get isInitialized => _db != null;

  Database get db {
    if (_db == null) throw StateError('DatabaseService not initialized. Call init() first.');
    return _db!;
  }

  String get dbPath {
    if (_dbPath == null) throw StateError('DatabaseService not initialized. Call init() first.');
    return _dbPath!;
  }

  Future<void> init() async {
    if (_db != null) return;
    if (kIsWeb) return;

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
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
    // _dbPath intentionally preserved so dbPath still works after close()
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
        notice TEXT,
        imageUrl TEXT,
        prices TEXT,
        pairings TEXT,
        updatedAt INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE cabinets (
        id   TEXT PRIMARY KEY,
        name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE shelves (
        id          TEXT PRIMARY KEY,
        cabinet_id  TEXT NOT NULL REFERENCES cabinets(id) ON DELETE CASCADE,
        name        TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE positions (
        id             TEXT PRIMARY KEY,
        shelf_id       TEXT NOT NULL REFERENCES shelves(id) ON DELETE CASCADE,
        position_index INTEGER NOT NULL,
        wine_id        TEXT
      )
    ''');
  }

}
