// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dio/dio.dart' as _i361;
import 'package:get_it/get_it.dart' as _i174;
import 'package:home_wine/core/database/database_service.dart' as _i886;
import 'package:home_wine/core/dependencies/module.dart' as _i997;
import 'package:home_wine/core/storage/storage_service.dart' as _i1036;
import 'package:home_wine/core/sync/ucloud_sync_service.dart' as _i860;
import 'package:home_wine/feature/login_page/presentation/cubit/login_cubit.dart'
    as _i365;
import 'package:home_wine/feature/main_page/data/reposiotry/main_repository.dart'
    as _i536;
import 'package:home_wine/feature/main_page/presentation/cubit/main_cubit.dart'
    as _i84;
import 'package:home_wine/feature/manage_storage_page/presentation/page/manage_storage_cubit.dart'
    as _i87;
import 'package:home_wine/feature/profile_page/data/repository/profile_repository.dart'
    as _i997;
import 'package:home_wine/feature/profile_page/presentation/cubit/profile_cubit.dart'
    as _i13;
import 'package:home_wine/feature/wine/data/repository/wine_repository.dart'
    as _i286;
import 'package:home_wine/feature/wine/presentation/cubit/wine_details_cubit.dart'
    as _i616;
import 'package:home_wine/feature/wine/presentation/cubit/wine_search_cubit.dart'
    as _i984;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final injectionModule = _$InjectionModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => injectionModule.prefs,
      preResolve: true,
    );
    gh.lazySingleton<_i886.DatabaseService>(() => _i886.DatabaseService());
    gh.lazySingleton<_i361.Dio>(() => injectionModule.dio);
    gh.factory<_i286.WineRepository>(
      () => _i286.WineRepositoryImpl(gh<_i361.Dio>()),
    );
    gh.factory<_i616.WineDetailsCubit>(
      () => _i616.WineDetailsCubit(gh<_i286.WineRepository>()),
    );
    gh.factory<_i984.WineSearchCubit>(
      () => _i984.WineSearchCubit(gh<_i286.WineRepository>()),
    );
    gh.lazySingleton<_i1036.StorageService>(
      () => _i1036.StorageService(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i860.UCloudSyncService>(
      () => _i860.UCloudSyncService(gh<_i886.DatabaseService>()),
    );
    gh.factory<_i365.LoginCubit>(
      () => _i365.LoginCubit(gh<_i860.UCloudSyncService>()),
    );
    gh.factory<_i536.MainRepository>(
      () => _i536.MainRepositoryImpl(
        gh<_i886.DatabaseService>(),
        gh<_i860.UCloudSyncService>(),
      ),
    );
    gh.factory<_i997.ProfileRepository>(
      () => _i997.ProfileRepositoryImpl(
        gh<_i886.DatabaseService>(),
        gh<_i860.UCloudSyncService>(),
      ),
    );
    gh.factory<_i84.MainCubit>(
      () => _i84.MainCubit(
        gh<_i536.MainRepository>(),
        gh<_i997.ProfileRepository>(),
      ),
    );
    gh.factory<_i13.ProfileCubit>(
      () => _i13.ProfileCubit(gh<_i997.ProfileRepository>()),
    );
    gh.factory<_i87.ManageStorageCubit>(
      () => _i87.ManageStorageCubit(
        gh<_i997.ProfileRepository>(),
        gh<_i536.MainRepository>(),
      ),
    );
    return this;
  }
}

class _$InjectionModule extends _i997.InjectionModule {}
