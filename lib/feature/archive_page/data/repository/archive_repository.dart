import 'dart:convert';

import 'package:wine_cellar/core/database/database_service.dart';
import 'package:wine_cellar/feature/wine/data/models/wine_model.dart';
import 'package:sqflite/sqflite.dart';

class ArchivedWine {
  final WineModel wine;
  final DateTime archivedAt;

  const ArchivedWine({required this.wine, required this.archivedAt});
}

abstract class ArchiveRepository {
  Future<List<ArchivedWine>> getArchivedWines();
  Future<void> restoreWine(String wineId);
  Future<void> permanentlyDelete(String wineId);
}

class ArchiveRepositoryImpl implements ArchiveRepository {
  final DatabaseService _db;

  ArchiveRepositoryImpl(this._db);

  @override
  Future<List<ArchivedWine>> getArchivedWines() async {
    final rows = await _db.db.rawQuery('''
      SELECT aw.*, ar.archived_at
      FROM all_wines aw
      JOIN archive ar ON aw.id = ar.wine_id
      LEFT JOIN cellar_wines cw ON aw.id = cw.wine_id
      WHERE cw.wine_id IS NULL
      ORDER BY ar.archived_at DESC
    ''');

    return rows.map((row) {
      final wine = WineModel.fromJson({
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
        'prices': row['prices'] != null ? jsonDecode(row['prices'] as String) : null,
        'pairings': row['pairings'] != null ? jsonDecode(row['pairings'] as String) : null,
        'grapes': row['grapes'] != null ? jsonDecode(row['grapes'] as String) : null,
        'scores': row['scores'] != null ? jsonDecode(row['scores'] as String) : null,
      });
      final archivedAt = DateTime.fromMillisecondsSinceEpoch(row['archived_at'] as int);
      return ArchivedWine(wine: wine, archivedAt: archivedAt);
    }).toList();
  }

  @override
  Future<void> restoreWine(String wineId) async {
    await _db.db.transaction((txn) async {
      await txn.delete('archive', where: 'wine_id = ?', whereArgs: [wineId]);
      await txn.insert(
        'cellar_wines',
        {'wine_id': wineId, 'quantity': 1},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  @override
  Future<void> permanentlyDelete(String wineId) async {
    final db = _db.db;
    await db.delete('archive', where: 'wine_id = ?', whereArgs: [wineId]);

    final inWishlist = await db.query('wishlist', columns: ['wine_id'],
        where: 'wine_id = ?', whereArgs: [wineId], limit: 1);
    final inCellar = await db.query('cellar_wines', columns: ['wine_id'],
        where: 'wine_id = ?', whereArgs: [wineId], limit: 1);
    if (inWishlist.isEmpty && inCellar.isEmpty) {
      await db.delete('all_wines', where: 'id = ?', whereArgs: [wineId]);
    }
  }
}
