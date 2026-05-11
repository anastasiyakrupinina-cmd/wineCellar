import 'package:flutter/foundation.dart';
import 'package:home_wine/feature/wine/data/models/wine_model.dart';

@immutable
sealed class WineDetailsState {}

final class WineDetailsInitial extends WineDetailsState {}

final class WineDetailsLoading extends WineDetailsState {}

final class WineDetailsSuccess extends WineDetailsState {
  final WineModel wine;
  WineDetailsSuccess(this.wine);
}

final class WineDetailsError extends WineDetailsState {
  final String message;
  WineDetailsError(this.message);
}
