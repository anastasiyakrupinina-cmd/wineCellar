import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wine_cellar/feature/profile_page/data/repository/profile_repository.dart';
import 'package:wine_cellar/feature/profile_page/presentation/cubit/profile_state.dart';
import 'package:injectable/injectable.dart';

@injectable
class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository _repository;

  ProfileCubit(this._repository) : super(ProfileInitial());

  Future<void> loadProfile() async {
    final username = await _repository.getCurrentUsername();
    emit(ProfileLoaded(username ?? ''));
  }

  Future<void> signOut() async {
    emit(ProfileLoading());
    try {
      await _repository.signOut();
      emit(ProfileUnauthenticated());
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }
}
