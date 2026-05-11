import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_wine/feature/wine/data/repository/wine_repository.dart';
import 'package:injectable/injectable.dart';

import 'wine_details_state.dart';

@injectable
class WineDetailsCubit extends Cubit<WineDetailsState> {
  final WineRepository _repository;

  WineDetailsCubit(this._repository) : super(WineDetailsInitial());

  Future<void> getWineDetails(String id) async {
    emit(WineDetailsLoading());
    try {
      final wine = await _repository.getWineDetails(id);
      emit(WineDetailsSuccess(wine));
    } catch (e) {
      emit(WineDetailsError(e.toString()));
    }
  }
}
