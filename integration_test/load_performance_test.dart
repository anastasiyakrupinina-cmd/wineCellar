import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:wine_cellar/feature/wine/data/models/wine_model.dart';
import 'package:wine_cellar/feature/wine/data/models/wine_bottle.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('getLocalWines loads 500 wines under 200ms on device', (tester) async {
    // Resolve the same DB path DatabaseService uses on Android.
    final String dbPath;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      sqflite.databaseFactory = databaseFactoryFfi;
      final dir = await getApplicationDocumentsDirectory();
      dbPath = p.join(dir.path, 'winecellar_perf_test.db');
    } else {
      final dir = await sqflite.getDatabasesPath();
      dbPath = p.join(dir, 'winecellar_perf_test.db');
    }

    // Delete any leftover from a previous run.
    final file = File(dbPath);
    if (file.existsSync()) file.deleteSync();

    final db = await sqflite.openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, _) async {
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
          CREATE TABLE cellar_wines (
            wine_id  TEXT PRIMARY KEY,
            quantity INTEGER NOT NULL DEFAULT 1,
            notice   TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE wine_bottles (
            id TEXT PRIMARY KEY, wine_id TEXT NOT NULL,
            bottle_size TEXT NOT NULL, quantity INTEGER NOT NULL DEFAULT 1
          )
        ''');
        await db.execute('CREATE TABLE cabinets (id TEXT PRIMARY KEY, name TEXT NOT NULL)');
        await db.execute('CREATE TABLE shelves  (id TEXT PRIMARY KEY, cabinet_id TEXT NOT NULL, name TEXT NOT NULL)');
        await db.execute('''
          CREATE TABLE positions (
            id TEXT PRIMARY KEY, shelf_id TEXT NOT NULL,
            position_index INTEGER NOT NULL, wine_id TEXT, bottle_size TEXT
          )
        ''');
      },
    );

    // ── Seed 500 wines ────────────────────────────────────────────────────────
    final grapes   = jsonEncode(['Cabernet Sauvignon', 'Merlot']);
    final prices   = jsonEncode([{'merchantName': 'Wine Shop', 'price': 25.99, 'currency': 'EUR', 'url': null}]);
    final pairings = jsonEncode([{'food': 'Beef'}, {'food': 'Lamb'}, {'food': 'Cheese'}]);
    final scores   = jsonEncode([{'score': 92.0, 'scoreText': 'Excellent', 'reviewer': 'Robert Parker', 'reviewDate': '2023-01-01'}]);

    final batch = db.batch();
    for (int i = 0; i < 500; i++) {
      final id = 'wine_$i';
      batch.insert('all_wines', {
        'id':            id,
        'name':          'Wine $i',
        'vintage':       2010 + (i % 14),
        'type':          ['Red', 'White', 'Rosé'][i % 3],
        'winery':        'Winery ${i % 50}',
        'region':        'Region ${i % 20}',
        'country':       'Country ${i % 10}',
        'averageRating': 85.0 + (i % 15),
        'ratingsCount':  100 + i,
        'description':   'A fine wine with notes of oak and berry. Entry $i.',
        'alcoholContent': '13.5%',
        'prices':   prices,
        'pairings': pairings,
        'grapes':   grapes,
        'scores':   scores,
      });
      batch.insert('cellar_wines', {
        'wine_id':  id,
        'quantity': 1 + (i % 5),
        'notice':   null,
      });
    }
    await batch.commit(noResult: true);

    // ── Measure: exact getLocalWines() logic ──────────────────────────────────
    final sw = Stopwatch()..start();

    final wineRows = await db.rawQuery('''
      SELECT aw.*, cw.quantity, cw.notice
      FROM   all_wines aw
      JOIN   cellar_wines cw ON aw.id = cw.wine_id
      ORDER  BY aw.name ASC
    ''');

    final bottleRows = await db.query('wine_bottles');
    final bottlesByWineId = <String, List<WineBottle>>{};
    for (final row in bottleRows) {
      final wineId = row['wine_id'] as String;
      (bottlesByWineId[wineId] ??= [])
          .add(WineBottle.fromMap(Map<String, dynamic>.from(row)));
    }

    final posRows = await db.rawQuery('''
      SELECT p.wine_id, c.name AS cabinet_name, s.name AS shelf_name, p.position_index
      FROM   positions p
      JOIN   shelves  s ON p.shelf_id   = s.id
      JOIN   cabinets c ON s.cabinet_id = c.id
      WHERE  p.wine_id IS NOT NULL
      ORDER  BY c.name, s.name, p.position_index
    ''');

    final grouped = <String, Map<String, List<int>>>{};
    for (final row in posRows) {
      final wineId = row['wine_id'] as String;
      final key    = '${row['cabinet_name']} > ${row['shelf_name']}';
      (grouped[wineId] ??= {})[key] = [
        ...(grouped[wineId]?[key] ?? []),
        row['position_index'] as int,
      ];
    }

    final locations = grouped.map((wineId, shelfMap) {
      final parts = shelfMap.entries
          .map((e) => '${e.key} > Spot ${e.value.join(', ')}')
          .toList()
        ..sort();
      return MapEntry(wineId, parts.join(' ; '));
    });

    final wines = wineRows.map((row) {
      final wineId = row['id'] as String;
      return WineModel.fromJson({
        'id':            row['id'],
        'name':          row['name'],
        'vintage':       row['vintage'],
        'type':          row['type'],
        'winery':        row['winery'],
        'region':        row['region'],
        'country':       row['country'],
        'averageRating': row['averageRating'],
        'ratingsCount':  row['ratingsCount'],
        'description':   row['description'],
        'alcoholContent':row['alcoholContent'],
        'quantity':      row['quantity'],
        'cellarLocation':locations[wineId],
        'notice':        row['notice'],
        'prices':   row['prices'] != null ? jsonDecode(row['prices']  as String) : null,
        'pairings': null,
        'grapes':   row['grapes'] != null ? jsonDecode(row['grapes']  as String) : null,
        'scores':   null,
      }).copyWith(
        rawPairingsJson: row['pairings'] as String?,
        rawScoresJson:   row['scores']   as String?,
        bottles: bottlesByWineId[wineId],
      );
    }).toList();

    sw.stop();
    // ─────────────────────────────────────────────────────────────────────────

    debugPrint('═══ PERF: getLocalWines: ${sw.elapsedMilliseconds}ms for ${wines.length} wines ═══');

    await db.close();
    file.deleteSync(); // clean up test DB

    expect(wines.length, 500);
    expect(
      sw.elapsedMilliseconds,
      lessThan(200),
      reason: 'Load took ${sw.elapsedMilliseconds}ms — exceeds 200ms budget',
    );
  });
}
