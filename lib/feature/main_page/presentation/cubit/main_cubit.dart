import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_wine/feature/main_page/data/reposiotry/main_repository.dart';
import 'package:home_wine/feature/profile_page/data/repository/profile_repository.dart';
import 'package:home_wine/feature/profile_page/data/repository/storage_model.dart';
import 'package:home_wine/feature/wine/data/models/wine_model.dart';
import 'package:injectable/injectable.dart';

import 'main_state.dart';

@injectable
class MainCubit extends Cubit<MainState> {
  final MainRepository _repository;
  final ProfileRepository _profileRepository;

  MainCubit(this._repository, this._profileRepository) : super(MainInitial());

  Future<void> loadWines() async {
    if (isClosed) return;

    
    try {
      final localWines = await _repository.getLocalWines();
      if (localWines.isNotEmpty) {
        if (!isClosed) emit(MainLoaded(localWines));
      } else {
        if (!isClosed) emit(MainLoading());
      }
    } catch (e) {
      if (!isClosed) emit(MainLoading());
    }

    
    try {
      final remoteWines = await _repository.getRemoteWines();
      if (!isClosed) emit(MainLoaded(remoteWines));
    } catch (e) {
      
      if (state is! MainLoaded && !isClosed) {
        emit(MainError(e.toString()));
      }
    }
  }

  Future<void> saveWine(WineModel wine) async {
    try {
      
      if (state is MainLoaded) {
        final currentWines = List<WineModel>.from((state as MainLoaded).wines);
        final index = currentWines.indexWhere((w) => w.id == wine.id);
        if (index != -1) {
          currentWines[index] = wine;
        } else {
          currentWines.add(wine);
        }
        emit(MainLoaded(currentWines));
      }

      await _repository.saveWine(wine);
      loadWines(); 
    } catch (e) {
      if (!isClosed) emit(MainError(e.toString()));
    }
  }

  Future<void> deleteWine(String wineId) async {
    try {
      
      if (state is MainLoaded) {
        final currentWines = List<WineModel>.from((state as MainLoaded).wines);
        currentWines.removeWhere((w) => w.id == wineId);
        emit(MainLoaded(currentWines));
      }

      await _freeAllSpots(wineId);
      await _repository.deleteWine(wineId);
      loadWines();
    } catch (e) {
      if (!isClosed) emit(MainError(e.toString()));
    }
  }

  Future<void> updateQuantity(WineModel wine, int newQuantity) async {
    try {
      if (newQuantity <= 0) {
        await deleteWine(wine.id);
      } else {
        int diff = newQuantity - wine.quantity;
        String? newLocation = wine.cellarLocation;

        
        
        if (diff < 0) {
          newLocation = await _freeSpots(wine, -diff);
        }

        final updatedWine = wine.copyWith(quantity: newQuantity, cellarLocation: newLocation);

        
        if (state is MainLoaded) {
          final currentWines = List<WineModel>.from((state as MainLoaded).wines);
          final index = currentWines.indexWhere((w) => w.id == wine.id);
          if (index != -1) currentWines[index] = updatedWine;
          emit(MainLoaded(currentWines));
        }

        await _repository.saveWine(updatedWine);
        loadWines();
      }
    } catch (e) {
      if (!isClosed) emit(MainError(e.toString()));
    }
  }

  Future<void> _freeAllSpots(String wineId) async {
    final cabinets = await _profileRepository.getStorageLocations();

    for (var cab in cabinets) {
      bool cabChanged = false;
      final newShelves = cab.shelves.map((shelf) {
        bool shelfChanged = false;
        final newPositions = shelf.positions.map((pos) {
          if (pos.wineId == wineId) {
            shelfChanged = true;
            return BottlePositionModel(id: pos.id, index: pos.index, wineId: null);
          }
          return pos;
        }).toList();

        if (shelfChanged) cabChanged = true;
        return shelfChanged ? ShelfModel(id: shelf.id, name: shelf.name, positions: newPositions) : shelf;
      }).toList();

      if (cabChanged) {
        await _profileRepository.saveCabinet(CabinetModel(id: cab.id, name: cab.name, shelves: newShelves));
      }
    }
  }

  Future<String?> _freeSpots(WineModel wine, int countToRemove) async {
    final cabinets = await _profileRepository.getStorageLocations();
    final spotRefs = <({
      CabinetModel cabinet,
      ShelfModel shelf,
      BottlePositionModel position,
    })>[];

    for (final cab in cabinets) {
      for (final shelf in cab.shelves) {
        for (final pos in shelf.positions) {
          if (pos.wineId == wine.id) {
            spotRefs.add((cabinet: cab, shelf: shelf, position: pos));
          }
        }
      }
    }

    if (spotRefs.isEmpty) return wine.cellarLocation;

    spotRefs.sort((a, b) => b.position.index.compareTo(a.position.index));
    final toRemoveIds = spotRefs.take(countToRemove).map((e) => e.position.id).toSet();
    if (toRemoveIds.isEmpty) return wine.cellarLocation;

    final keptSpotsByShelf = <String, ({String cabinetName, String shelfName, List<int> indexes})>{};

    for (final cab in cabinets) {
      bool cabChanged = false;
      final updatedShelves = cab.shelves.map((shelf) {
        bool shelfChanged = false;
        final updatedPositions = shelf.positions.map((pos) {
          if (pos.wineId == wine.id && toRemoveIds.contains(pos.id)) {
            shelfChanged = true;
            return BottlePositionModel(id: pos.id, index: pos.index, wineId: null);
          }
          return pos;
        }).toList();

        final keptIndexes = updatedPositions
            .where((pos) => pos.wineId == wine.id)
            .map((pos) => pos.index)
            .toList()
          ..sort();
        if (keptIndexes.isNotEmpty) {
          keptSpotsByShelf['${cab.id}::${shelf.id}'] = (
            cabinetName: cab.name,
            shelfName: shelf.name,
            indexes: keptIndexes,
          );
        }

        if (shelfChanged) cabChanged = true;
        return shelfChanged ? ShelfModel(id: shelf.id, name: shelf.name, positions: updatedPositions) : shelf;
      }).toList();

      if (cabChanged) {
        await _profileRepository.saveCabinet(CabinetModel(id: cab.id, name: cab.name, shelves: updatedShelves));
      }
    }

    if (keptSpotsByShelf.isEmpty) return '';

    final updatedLocations = keptSpotsByShelf.values
        .map((entry) => '${entry.cabinetName} > ${entry.shelfName} > Spot ${entry.indexes.join(', ')}')
        .toList()
      ..sort();

    return updatedLocations.join(' ; ');
  }
}
