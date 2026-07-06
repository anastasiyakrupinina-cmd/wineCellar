import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wine_cellar/core/database/database_service.dart';
import 'package:wine_cellar/core/storage/storage_service.dart';
import 'package:wine_cellar/core/sync/ucloud_sync_service.dart';
import 'package:injectable/injectable.dart';

import 'login_state.dart';

@injectable
class LoginCubit extends Cubit<LoginState> {
  final UCloudSyncService _syncService;
  final DatabaseService _databaseService;
  final StorageService _storageService;

  LoginCubit(this._syncService, this._databaseService, this._storageService) : super(LoginInitial());

  Future<void> openLocalDatabase(File file) async {
    emit(LoginLoading());
    try {
      await _databaseService.openAtPath(file.path);
      await _storageService.saveString(StorageService.localDbPathKey, file.path);
      emit(LoginSuccess());
    } catch (e) {
      emit(LoginFailure('Could not open database file: ${e.toString()}'));
    }
  }

  Future<void> login(String username, String password) async {
    emit(LoginLoading());
    try {
      final isValid = await _syncService.validateCredentials(username, password);
      if (isValid) {
        await _syncService.saveCredentials(username, password);
        await _syncService.clearDirty();
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
