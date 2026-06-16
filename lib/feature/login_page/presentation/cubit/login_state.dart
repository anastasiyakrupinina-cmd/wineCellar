import 'package:flutter/foundation.dart';

@immutable
sealed class LoginState {}

final class LoginInitial extends LoginState {}

final class LoginLoading extends LoginState {}

final class LoginSuccess extends LoginState {}

final class LoginSyncConflict extends LoginState {}

final class LoginFailure extends LoginState {
  final String message;
  LoginFailure(this.message);
}
