import 'package:flutter/foundation.dart';
import 'package:wine_cellar/feature/wine/data/models/wine_model.dart';

@immutable
sealed class WineSearchState {}

final class WineSearchInitial extends WineSearchState {}

final class WineSearchLoading extends WineSearchState {}

final class WineSearchSuccess extends WineSearchState {
  final List<WineModel> wines;

  final bool isLastPage;

  WineSearchSuccess(this.wines, {this.isLastPage = false});

  WineSearchSuccess copyWith({List<WineModel>? wines, bool? isLastPage}) {
    return WineSearchSuccess(wines ?? this.wines, isLastPage: isLastPage ?? this.isLastPage);
  }
}

final class WineSearchError extends WineSearchState {
  final String message;
  WineSearchError(this.message);
}
