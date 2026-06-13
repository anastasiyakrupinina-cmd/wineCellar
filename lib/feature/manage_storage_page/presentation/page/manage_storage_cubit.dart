import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wine_cellar/feature/manage_storage_page/presentation/page/manage_storage_state.dart';
import 'package:wine_cellar/feature/profile_page/data/repository/profile_repository.dart';
import 'package:wine_cellar/feature/profile_page/data/repository/storage_model.dart';
import 'package:injectable/injectable.dart';

@injectable
class ManageStorageCubit extends Cubit<ManageStorageState> {
  final ProfileRepository _repository;

  ManageStorageCubit(this._repository) : super(ManageStorageInitial());

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
          (index) => BottlePositionModel(
            id: '${DateTime.now().millisecondsSinceEpoch}_$index',
            index: index + 1,
          ),
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
}
