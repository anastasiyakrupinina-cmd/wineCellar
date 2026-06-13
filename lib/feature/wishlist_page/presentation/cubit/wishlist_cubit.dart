import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wine_cellar/feature/wine/data/models/wine_model.dart';
import 'package:wine_cellar/feature/wishlist_page/data/repository/wishlist_repository.dart';
import 'package:wine_cellar/feature/wishlist_page/presentation/cubit/wishlist_state.dart';

class WishlistCubit extends Cubit<WishlistState> {
  final WishlistRepository _repository;

  WishlistCubit(this._repository) : super(WishlistInitial());

  Future<void> load() async {
    try {
      final wines = await _repository.getWishlist();
      emit(WishlistLoaded(wines));
    } catch (e) {
      emit(WishlistError(e.toString()));
    }
  }

  bool isWishlisted(String wineId) {
    final s = state;
    if (s is WishlistLoaded) return s.wines.any((w) => w.id == wineId);
    return false;
  }

  Future<void> toggle(WineModel wine) async {
    try {
      if (isWishlisted(wine.id)) {
        await _repository.removeFromWishlist(wine.id);
      } else {
        await _repository.addToWishlist(wine);
      }
      await load();
    } catch (e) {
      emit(WishlistError(e.toString()));
    }
  }

  Future<void> remove(String wineId) async {
    try {
      await _repository.removeFromWishlist(wineId);
      await load();
    } catch (e) {
      emit(WishlistError(e.toString()));
    }
  }
}
