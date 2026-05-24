import 'dart:convert';

import 'package:home_wine/core/database/database_service.dart';
import 'package:home_wine/feature/wine/data/models/wine_model.dart';
import 'package:sqflite/sqflite.dart';

abstract class WishlistRepository {
  Future<List<WineModel>> getWishlist();
  Future<void> addToWishlist(WineModel wine);
  Future<void> removeFromWishlist(String wineId);
  Future<bool> isInWishlist(String wineId);
}

class WishlistRepositoryImpl implements WishlistRepository {
  final DatabaseService _db;

  WishlistRepositoryImpl(this._db);

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
  }

  @override
  Future<List<WineModel>> getWishlist() async {
    final rows = await _db.db.rawQuery('''
      SELECT aw.*
      FROM   all_wines aw
      JOIN   wishlist  wl ON aw.id = wl.wine_id
      ORDER  BY wl.added_at DESC
    ''');
    return rows.map((row) => WineModel.fromJson({
      'id':             row['id'],
      'name':           row['name'],
      'vintage':        row['vintage'],
      'type':           row['type'],
      'winery':         row['winery'],
      'region':         row['region'],
      'country':        row['country'],
      'averageRating':  row['averageRating'],
      'ratingsCount':   row['ratingsCount'],
      'description':    row['description'],
      'alcoholContent': row['alcoholContent'],
      'imageUrl':       row['imageUrl'],
      'prices':   row['prices']   != null ? jsonDecode(row['prices']   as String) : null,
      'pairings': row['pairings'] != null ? jsonDecode(row['pairings'] as String) : null,
      'grapes':   row['grapes']   != null ? jsonDecode(row['grapes']   as String) : null,
      'scores':   row['scores']   != null ? jsonDecode(row['scores']   as String) : null,
    })).toList();
  }

  @override
  Future<void> addToWishlist(WineModel wine) async {
    await _db.db.transaction((txn) async {
      await _upsertAllWines(txn, wine);
      // IGNORE preserves added_at if already wishlisted
      await txn.insert(
        'wishlist',
        {'wine_id': wine.id, 'added_at': DateTime.now().millisecondsSinceEpoch},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    });
  }

  @override
  Future<void> removeFromWishlist(String wineId) async {
    final db = _db.db;
    await db.delete('wishlist', where: 'wine_id = ?', whereArgs: [wineId]);

    // Only remove from all_wines if not in the cellar
    final inCellar = await db.query(
      'cellar_wines', columns: ['wine_id'],
      where: 'wine_id = ?', whereArgs: [wineId], limit: 1,
    );
    if (inCellar.isEmpty) {
      await db.delete('all_wines', where: 'id = ?', whereArgs: [wineId]);
    }
  }

  @override
  Future<bool> isInWishlist(String wineId) async {
    final rows = await _db.db.query(
      'wishlist',
      where: 'wine_id = ?',
      whereArgs: [wineId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }
}
