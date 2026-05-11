import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_wine/core/storage/storage_service.dart';

class AppSettingsState {
  final bool showCabinetView;

  const AppSettingsState({this.showCabinetView = true});
}

class AppSettingsCubit extends Cubit<AppSettingsState> {
  final StorageService _storageService;
  static const String _viewPreferenceKey = 'main_page_view_preference';

  AppSettingsCubit(this._storageService) : super(const AppSettingsState()) {
    _loadSettings();
  }

  void _loadSettings() {
    final showCabinetView = _storageService.getBool(_viewPreferenceKey, defaultValue: true);
    emit(AppSettingsState(showCabinetView: showCabinetView));
  }

  Future<void> toggleCabinetView(bool value) async {
    await _storageService.saveBool(_viewPreferenceKey, value);
    emit(AppSettingsState(showCabinetView: value));
  }
}
