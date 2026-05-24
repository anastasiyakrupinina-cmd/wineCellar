import 'package:home_wine/feature/wine/data/models/wine_model.dart';

abstract class WishlistState {}

class WishlistInitial extends WishlistState {}

class WishlistLoaded extends WishlistState {
  final List<WineModel> wines;
  WishlistLoaded(this.wines);
}

class WishlistError extends WishlistState {
  final String message;
  WishlistError(this.message);
}
