import 'package:flutter/foundation.dart';

@immutable
class CatalogFilters {
  final List<String> names;
  final List<String> wineries;
  final List<String> types;
  final List<String> countries;
  final List<String> grapes;

  const CatalogFilters({
    this.names = const [],
    this.wineries = const [],
    this.types = const [],
    this.countries = const [],
    this.grapes = const [],
  });

  bool get isEmpty =>
      names.isEmpty &&
      wineries.isEmpty &&
      types.isEmpty &&
      countries.isEmpty &&
      grapes.isEmpty;

  List<String> get allOptions =>
      [...names, ...wineries, ...types, ...countries, ...grapes];
}
