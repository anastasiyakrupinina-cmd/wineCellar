import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_wine/feature/main_page/data/reposiotry/main_repository.dart';
import 'package:home_wine/feature/manage_storage_page/presentation/page/manage_storage_state.dart';
import 'package:home_wine/feature/profile_page/data/repository/profile_repository.dart';
import 'package:home_wine/feature/profile_page/data/repository/storage_model.dart';
import 'package:home_wine/feature/wine/data/models/wine_model.dart';
import 'package:injectable/injectable.dart';

@injectable
class ManageStorageCubit extends Cubit<ManageStorageState> {
  final ProfileRepository _repository;
  final MainRepository _mainRepository;

  ManageStorageCubit(this._repository, this._mainRepository) : super(ManageStorageInitial());

  Future<void> loadCabinets() async {
    emit(ManageStorageLoading());
    try {
      final cabinets = await _repository.getStorageLocations();
      emit(ManageStorageLoaded(cabinets));
    } catch (e) {
      emit(ManageStorageError(e.toString()));
    }
  }

  Future<void> addCabinet(String name) async {
    try {
      final newCabinet = CabinetModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        shelves: [],
      );
      await _repository.saveCabinet(newCabinet);
      await loadCabinets();
    } catch (e) {
      emit(ManageStorageError(e.toString()));
    }
  }

  Future<void> deleteCabinet(CabinetModel cabinet) async {
    try {
      await _moveCabinetWinesToUnassigned(cabinet);
      await _repository.deleteCabinet(cabinet.id);
      await loadCabinets();
    } catch (e) {
      emit(ManageStorageError(e.toString()));
    }
  }

  Future<void> addShelf(CabinetModel cabinet, String shelfName, int positionsCount) async {
    try {
      final newShelf = ShelfModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: shelfName,
        positions: List.generate(
          positionsCount,
          (index) =>
              BottlePositionModel(id: '${DateTime.now().millisecondsSinceEpoch}_$index', index: index + 1),
        ),
      );
      final updatedCabinet = CabinetModel(
        id: cabinet.id,
        name: cabinet.name,
        shelves: [...cabinet.shelves, newShelf],
      );
      await _repository.saveCabinet(updatedCabinet);
      await loadCabinets();
    } catch (e) {
      emit(ManageStorageError(e.toString()));
    }
  }

  Future<void> _moveCabinetWinesToUnassigned(CabinetModel cabinet) async {
    final occupiedWineIds = cabinet.shelves
        .expand((shelf) => shelf.positions)
        .map((pos) => pos.wineId)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();

    if (occupiedWineIds.isEmpty) return;

    List<WineModel> wines;
    try {
      wines = await _mainRepository.getRemoteWines();
    } catch (_) {
      wines = await _mainRepository.getLocalWines();
    }
    final winesById = <String, WineModel>{for (final wine in wines) wine.id: wine};

    for (final wineId in occupiedWineIds) {
      final wine = winesById[wineId];
      if (wine == null) continue;

      final updatedLocation = _removeCabinetFromLocation(wine.cellarLocation, cabinet.name);
      await _mainRepository.saveWine(wine.copyWith(cellarLocation: updatedLocation));
    }
  }

  String _removeCabinetFromLocation(String? location, String cabinetName) {
    final raw = location?.trim() ?? '';
    if (raw.isEmpty || raw == 'Unassigned') return 'Unassigned';

    final remaining = raw
        .split(' ; ')
        .map((loc) => loc.trim())
        .where((loc) => loc.isNotEmpty && !loc.startsWith('$cabinetName >'))
        .toList();

    if (remaining.isEmpty) return 'Unassigned';
    return remaining.join(' ; ');
  }
}
