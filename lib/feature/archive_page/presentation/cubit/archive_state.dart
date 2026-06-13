import 'package:wine_cellar/feature/archive_page/data/repository/archive_repository.dart';

abstract class ArchiveState {}

class ArchiveInitial extends ArchiveState {}

class ArchiveLoading extends ArchiveState {}

class ArchiveLoaded extends ArchiveState {
  final List<ArchivedWine> wines;
  ArchiveLoaded(this.wines);
}

class ArchiveError extends ArchiveState {
  final String message;
  ArchiveError(this.message);
}
