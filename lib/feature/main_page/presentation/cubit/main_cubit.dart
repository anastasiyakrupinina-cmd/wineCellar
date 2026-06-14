import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wine_cellar/feature/main_page/data/reposiotry/main_repository.dart';
import 'package:wine_cellar/feature/profile_page/data/repository/profile_repository.dart';
import 'package:wine_cellar/feature/profile_page/data/repository/storage_model.dart';
import 'package:wine_cellar/feature/wine/data/models/wine_bottle.dart';
import 'package:wine_cellar/feature/wine/data/models/wine_model.dart';
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
        return;
      }

      final diff = newQuantity - wine.quantity;

      if (diff < 0) {
        await _profileRepository.freeSpots(wine.id, -diff);
      }

      final updatedWine = wine.copyWith(quantity: newQuantity);

      if (state is MainLoaded) {
        final currentWines = List<WineModel>.from((state as MainLoaded).wines);
        final index = currentWines.indexWhere((w) => w.id == wine.id);
        if (index != -1) currentWines[index] = updatedWine;
        emit(MainLoaded(currentWines));
      }

      await _repository.saveWine(updatedWine);
      loadWines();
    } catch (e) {
      if (!isClosed) emit(MainError(e.toString()));
    }
  }

  Future<void> updateBottleSizes(
    WineModel wine,
    List<WineBottle> newBottles, {
    bool skipPositionUpdate = false,
  }) async {
    try {
      final newTotal = newBottles.fold(0, (s, b) => s + b.quantity);

      if (newTotal <= 0) {
        await deleteWine(wine.id);
        return;
      }

      final oldTotal = wine.quantity;
      if (!skipPositionUpdate && newTotal < oldTotal) {
        await _profileRepository.freeSpots(wine.id, oldTotal - newTotal);
      }

      final updatedWine = wine.copyWith(bottles: newBottles, quantity: newTotal);

      if (state is MainLoaded) {
        final currentWines = List<WineModel>.from((state as MainLoaded).wines);
        final index = currentWines.indexWhere((w) => w.id == wine.id);
        if (index != -1) currentWines[index] = updatedWine;
        emit(MainLoaded(currentWines));
      }

      await _repository.saveWine(updatedWine);
      loadWines();
    } catch (e) {
      if (!isClosed) emit(MainError(e.toString()));
    }
  }

  Future<List<OccupiedSpot>> getOccupiedSpots(String wineId) =>
      _profileRepository.getOccupiedSpots(wineId);
}
