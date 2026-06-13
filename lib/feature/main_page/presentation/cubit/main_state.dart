import 'package:flutter/foundation.dart';
import 'package:wine_cellar/feature/wine/data/models/wine_model.dart';

@immutable
sealed class MainState {}

final class MainInitial extends MainState {}

final class MainLoading extends MainState {}

final class MainLoaded extends MainState {
  final List<WineModel> wines;
  MainLoaded(this.wines);
}

final class MainError extends MainState {
  final String message;
  MainError(this.message);
}
