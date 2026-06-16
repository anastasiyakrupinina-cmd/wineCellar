import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wine_cellar/core/sync/ucloud_sync_service.dart';
import 'package:injectable/injectable.dart';

import 'login_state.dart';

@injectable
class LoginCubit extends Cubit<LoginState> {
  final UCloudSyncService _syncService;

  LoginCubit(this._syncService) : super(LoginInitial());

  Future<void> login(String username, String password) async {
    emit(LoginLoading());
    try {
      final isValid = await _syncService.validateCredentials(username, password);
      if (isValid) {
        await _syncService.saveCredentials(username, password);
        final outcome = await _syncService.syncOnStart();
        if (outcome == SyncOutcome.conflict) {
          emit(LoginSyncConflict());
        } else {
          emit(LoginSuccess());
        }
      } else {
        emit(LoginFailure('Invalid u:cloud credentials. Use your university email and password.'));
      }
    } catch (e) {
      emit(LoginFailure('Connection error: ${e.toString()}'));
    }
  }

  Future<void> resolveConflict({required bool keepLocal}) async {
    emit(LoginLoading());
    if (keepLocal) {
      await _syncService.uploadDb();
    } else {
      await _syncService.resolveWithRemote();
    }
    emit(LoginSuccess());
  }
}
