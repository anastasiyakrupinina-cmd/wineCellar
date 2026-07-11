import 'dart:io';
import 'dart:typed_data';

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

  /// Reads the current database file's bytes for exporting (share/save-as).
  /// Checkpoints WAL first so recent writes aren't left behind in the
  /// sidecar `-wal` file, same as UCloudSyncService.uploadDb() does.
  Future<Uint8List> readBytesForExport() async {
    if (_db != null) {
      await _db!.rawQuery('PRAGMA wal_checkpoint(TRUNCATE)');
    }
    return File(dbPath).readAsBytes();
  }

  /// Desktop OSes hand back a real, writable filesystem path from a file
  /// picker, so a picked/created file can stay open and be written to
  /// directly. Android/iOS sandbox file access (SAF / scoped storage): a
  /// picked file's path is only a cached copy, and there's no way to keep
  /// writing into a user-chosen save location. So on mobile, local-only mode
  /// always operates on a copy kept in the app's own permanent storage.
  static bool get _supportsInPlaceEditing =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  Future<String> _resolveDbPath() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final dir = await getApplicationDocumentsDirectory();
      return p.join(dir.path, 'winecellar.db');
    } else {
      final dbDir = await getDatabasesPath();
      return p.join(dbDir, 'winecellar.db');
    }
  }

  Future<void> _openAt(String path) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    _dbPath = path;
    _db = await openDatabase(
      path,
      version: 10,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
  }

  Future<void> init() async {
    if (_db != null) return;
    await _openAt(await _resolveDbPath());
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
    // _dbPath intentionally preserved so dbPath still works after close()
  }

  /// Opens the database file at [path] directly (in place), closing whatever
  /// db was previously open. Future reads/writes go straight to this file.
  Future<void> openAtPath(String path) async {
    await close();
    await _openAt(path);
  }

  /// Opens [source], a file the user picked, as the local database. Returns
  /// the path that ends up open, which the caller should persist to reopen
  /// on the next launch. On desktop this opens [source] in place; on mobile
  /// its bytes are copied into the app's own permanent storage first (see
  /// [_supportsInPlaceEditing]).
  Future<String> openPickedFile(File source) async {
    if (_supportsInPlaceEditing) {
      await openAtPath(source.path);
      return source.path;
    }
    final path = await _resolveDbPath();
    await close();
    await source.copy(path);
    await _openAt(path);
    return path;
  }

  /// Creates/opens a fresh local database, returning the path that ends up
  /// open. On desktop this opens directly at [desktopPath] (a location the
  /// user chose via a save dialog). On mobile there's no way to keep writing
  /// into a user-chosen save location, so [desktopPath] is ignored and the
  /// app's own permanent storage is always used instead.
  Future<String> createLocalDatabase({String? desktopPath}) async {
    final path = _supportsInPlaceEditing && desktopPath != null
        ? desktopPath
        : await _resolveDbPath();
    await openAtPath(path);
    return path;
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
        wine_id        TEXT REFERENCES cellar_wines(wine_id) ON DELETE SET NULL,
        bottle_size    TEXT
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
