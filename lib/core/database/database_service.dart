import 'dart:io';

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
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
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
      version: 9,
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
      CREATE TABLE all_wines (
        id             TEXT PRIMARY KEY,
        name           TEXT NOT NULL,
        vintage        INTEGER,
        type           TEXT,
        winery         TEXT,
        region         TEXT,
        country        TEXT,
        averageRating  REAL,
        ratingsCount   INTEGER,
        description    TEXT,
        alcoholContent TEXT,
        prices         TEXT,
        pairings       TEXT,
        grapes         TEXT,
        scores         TEXT
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
        id         TEXT PRIMARY KEY,
        cabinet_id TEXT NOT NULL REFERENCES cabinets(id) ON DELETE CASCADE,
        name       TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE positions (
        id             TEXT PRIMARY KEY,
        shelf_id       TEXT NOT NULL REFERENCES shelves(id) ON DELETE CASCADE,
        position_index INTEGER NOT NULL,
        wine_id        TEXT REFERENCES cellar_wines(wine_id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE cellar_wines (
        wine_id  TEXT PRIMARY KEY REFERENCES all_wines(id) ON DELETE CASCADE,
        quantity INTEGER NOT NULL DEFAULT 1,
        notice   TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE wine_bottles (
        id          TEXT PRIMARY KEY,
        wine_id     TEXT NOT NULL REFERENCES cellar_wines(wine_id) ON DELETE CASCADE,
        bottle_size TEXT NOT NULL,
        quantity    INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE purchase_history (
        id            TEXT PRIMARY KEY,
        wine_id       TEXT NOT NULL REFERENCES all_wines(id) ON DELETE CASCADE,
        bottle_size   TEXT,
        quantity      INTEGER NOT NULL DEFAULT 1,
        price         REAL NOT NULL,
        currency      TEXT NOT NULL DEFAULT 'USD',
        purchased_at  INTEGER NOT NULL,
        shop_name     TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE wishlist (
        wine_id  TEXT PRIMARY KEY REFERENCES all_wines(id) ON DELETE CASCADE,
        added_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE archive (
        wine_id     TEXT PRIMARY KEY REFERENCES all_wines(id) ON DELETE CASCADE,
        archived_at INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('CREATE TABLE wineries (name TEXT PRIMARY KEY)');
    await db.execute('CREATE TABLE wine_types (name TEXT PRIMARY KEY)');
    await db.execute('CREATE TABLE countries (name TEXT PRIMARY KEY)');
    await db.execute('CREATE TABLE grapes (name TEXT PRIMARY KEY)');
    await db.execute('CREATE TABLE shops (name TEXT PRIMARY KEY)');
  }

}
