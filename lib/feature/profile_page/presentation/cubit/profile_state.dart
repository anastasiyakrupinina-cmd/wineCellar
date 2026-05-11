import 'package:flutter/foundation.dart';

@immutable
sealed class ProfileState {}

final class ProfileInitial extends ProfileState {}

final class ProfileLoading extends ProfileState {}

final class ProfileUnauthenticated extends ProfileState {}

final class ProfileLoaded extends ProfileState {
  final String username;
  ProfileLoaded(this.username);
}

final class ProfileError extends ProfileState {
  final String message;
  ProfileError(this.message);
}
