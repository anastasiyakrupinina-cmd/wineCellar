import 'package:wine_cellar/core/database/database_service.dart';
import 'package:wine_cellar/feature/wine/data/models/catalog_filters.dart';
import 'package:injectable/injectable.dart';

abstract class SearchRepository {
  Future<CatalogFilters> getFilterOptions();
  Future<CatalogFilters> getCatalogFilterOptions();
  Future<List<String>> getShopOptions();
}

@Injectable(as: SearchRepository)
class SearchRepositoryImpl implements SearchRepository {
  final DatabaseService _db;

  SearchRepositoryImpl(this._db);

  @override
  Future<List<String>> getShopOptions() async {
    final rows = await _db.db.query('shops', orderBy: 'name ASC');
    return rows.map((r) => r['name'] as String).toList();
  }

  @override
  Future<CatalogFilters> getCatalogFilterOptions() async {
    final db = _db.db;
    final names = (await db.rawQuery(
      'SELECT DISTINCT name FROM all_wines ORDER BY name ASC',
    )).map((r) => r['name'] as String).toList();
    final wineries = (await db.query('wineries', orderBy: 'name ASC'))
        .map((r) => r['name'] as String)
        .toList();
    final types = (await db.query('wine_types', orderBy: 'name ASC'))
        .map((r) => r['name'] as String)
        .toList();
    final countries = (await db.query('countries', orderBy: 'name ASC'))
        .map((r) => r['name'] as String)
        .toList();
    final grapes = (await db.query('grapes', orderBy: 'name ASC'))
        .map((r) => r['name'] as String)
        .toList();
    return CatalogFilters(
      names: names,
      wineries: wineries,
      types: types,
      countries: countries,
      grapes: grapes,
    );
  }

  @override
  Future<CatalogFilters> getFilterOptions() async {
    final db = _db.db;
    final names = (await db.rawQuery('''
      SELECT DISTINCT aw.name FROM all_wines aw
      JOIN cellar_wines cw ON aw.id = cw.wine_id
      ORDER BY aw.name ASC
    ''')).map((r) => r['name'] as String).toList();
    final wineries = (await db.query('wineries', orderBy: 'name ASC'))
        .map((r) => r['name'] as String)
        .toList();
    final types = (await db.query('wine_types', orderBy: 'name ASC'))
        .map((r) => r['name'] as String)
        .toList();
    final countries = (await db.query('countries', orderBy: 'name ASC'))
        .map((r) => r['name'] as String)
        .toList();
    final grapes = (await db.query('grapes', orderBy: 'name ASC'))
        .map((r) => r['name'] as String)
        .toList();

    return CatalogFilters(
      names: names,
      wineries: wineries,
      types: types,
      countries: countries,
      grapes: grapes,
    );
  }

}
