import 'package:flutter/foundation.dart';
import 'package:home_wine/feature/profile_page/data/repository/storage_model.dart';

@immutable
sealed class ManageStorageState {}

final class ManageStorageInitial extends ManageStorageState {}

final class ManageStorageLoading extends ManageStorageState {}

final class ManageStorageLoaded extends ManageStorageState {
  final List<CabinetModel> cabinets;
  ManageStorageLoaded(this.cabinets);
}

final class ManageStorageError extends ManageStorageState {
  final String message;
  ManageStorageError(this.message);
}
