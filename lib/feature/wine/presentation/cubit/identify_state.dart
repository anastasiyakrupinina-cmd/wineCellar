import 'package:home_wine/feature/wine/data/models/wine_model.dart';

sealed class IdentifyWineState {}

class IdentifyWineInitial extends IdentifyWineState {}

class IdentifyWineLoading extends IdentifyWineState {}

class IdentifyWineSuccess extends IdentifyWineState {
  final WineModel wine;
  IdentifyWineSuccess(this.wine);
}

class IdentifyWineNotFound extends IdentifyWineState {}

class IdentifyWineError extends IdentifyWineState {
  final String message;
  IdentifyWineError(this.message);
}
