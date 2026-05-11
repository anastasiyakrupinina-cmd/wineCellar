import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_wine/feature/wine/data/models/wine_model.dart';
import 'package:home_wine/feature/wine/data/repository/wine_repository.dart';
import 'package:injectable/injectable.dart';

import 'wine_search_state.dart';

@injectable
class WineSearchCubit extends Cubit<WineSearchState> {
  final WineRepository _repository;

  List<WineModel> _currentWines = [];
  int _currentOffset = 0;
  bool _isLastPage = false;
  String _lastQuery = '';
  bool _isLoadingMore = false;

  WineSearchCubit(this._repository) : super(WineSearchInitial());

  Future<void> searchWines({String query = ''}) async {
    _lastQuery = query;
    _currentOffset = 0;
    _isLastPage = false;

    emit(WineSearchLoading());
    try {
      final wines = await _repository.searchWines(query: query, limit: 20, offset: 0);
      _currentWines = wines;
      _isLastPage = wines.length < 20;
      emit(WineSearchSuccess(_currentWines, isLastPage: _isLastPage));
    } catch (e) {
      emit(WineSearchError(e.toString()));
    }
  }

  Future<void> loadMoreWines() async {
    if (_isLoadingMore || _isLastPage || state is WineSearchLoading) return;

    _isLoadingMore = true;
    _currentOffset += 20;

    try {
      final newWines = await _repository.searchWines(query: _lastQuery, limit: 20, offset: _currentOffset);

      if (newWines.isEmpty) {
        _isLastPage = true;
      } else {
        _currentWines = [..._currentWines, ...newWines];
        if (newWines.length < 20) _isLastPage = true;
      }

      emit(WineSearchSuccess(List.from(_currentWines), isLastPage: _isLastPage));
    } catch (e) {
      emit(WineSearchSuccess(_currentWines, isLastPage: _isLastPage));
    } finally {
      _isLoadingMore = false;
    }
  }
}
