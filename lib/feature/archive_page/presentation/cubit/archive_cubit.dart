import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:wine_cellar/feature/archive_page/data/repository/archive_repository.dart';
import 'package:wine_cellar/feature/archive_page/presentation/cubit/archive_state.dart';

@lazySingleton
class ArchiveCubit extends Cubit<ArchiveState> {
  final ArchiveRepository _repository;

  ArchiveCubit(this._repository) : super(ArchiveInitial());

  Future<void> load() async {
    try {
      emit(ArchiveLoading());
      final wines = await _repository.getArchivedWines();
      emit(ArchiveLoaded(wines));
    } catch (e) {
      emit(ArchiveError(e.toString()));
    }
  }

  Future<void> restore(String wineId) async {
    try {
      await _repository.restoreWine(wineId);
      await load();
    } catch (e) {
      emit(ArchiveError(e.toString()));
    }
  }

  Future<void> permanentlyDelete(String wineId) async {
    try {
      await _repository.permanentlyDelete(wineId);
      await load();
    } catch (e) {
      emit(ArchiveError(e.toString()));
    }
  }
}
