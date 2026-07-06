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
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;
import 'package:wine_cellar/core/database/database_service.dart' as _i964;
import 'package:wine_cellar/core/dependencies/module.dart' as _i465;
import 'package:wine_cellar/core/storage/storage_service.dart' as _i744;
import 'package:wine_cellar/core/sync/ucloud_sync_service.dart' as _i1027;
import 'package:wine_cellar/feature/archive_page/data/repository/archive_repository.dart'
    as _i857;
import 'package:wine_cellar/feature/archive_page/presentation/cubit/archive_cubit.dart'
    as _i708;
import 'package:wine_cellar/feature/login_page/presentation/cubit/login_cubit.dart'
    as _i115;
import 'package:wine_cellar/feature/main_page/data/reposiotry/main_repository.dart'
    as _i513;
import 'package:wine_cellar/feature/main_page/presentation/cubit/main_cubit.dart'
    as _i427;
import 'package:wine_cellar/feature/manage_storage_page/presentation/page/manage_storage_cubit.dart'
    as _i115;
import 'package:wine_cellar/feature/profile_page/data/repository/profile_repository.dart'
    as _i601;
import 'package:wine_cellar/feature/profile_page/presentation/cubit/profile_cubit.dart'
    as _i842;
import 'package:wine_cellar/feature/wine/data/repository/search_repository.dart'
    as _i880;
import 'package:wine_cellar/feature/wine/data/repository/wine_repository.dart'
    as _i44;
import 'package:wine_cellar/feature/wine/presentation/cubit/wine_search_cubit.dart'
    as _i130;
import 'package:wine_cellar/feature/wishlist_page/data/repository/wishlist_repository.dart'
    as _i135;
import 'package:wine_cellar/feature/wishlist_page/presentation/cubit/wishlist_cubit.dart'
    as _i342;

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
    gh.lazySingleton<_i964.DatabaseService>(() => _i964.DatabaseService());
    gh.lazySingleton<_i361.Dio>(() => injectionModule.dio);
    gh.factory<_i880.SearchRepository>(
      () => _i880.SearchRepositoryImpl(gh<_i964.DatabaseService>()),
    );
    gh.lazySingleton<_i1027.UCloudSyncService>(
      () => _i1027.UCloudSyncService(gh<_i964.DatabaseService>()),
    );
    gh.factory<_i857.ArchiveRepository>(
      () => _i857.ArchiveRepositoryImpl(gh<_i964.DatabaseService>()),
    );
    gh.factory<_i44.WineRepository>(
      () => _i44.WineRepositoryImpl(gh<_i361.Dio>()),
    );
    gh.factory<_i135.WishlistRepository>(
      () => _i135.WishlistRepositoryImpl(gh<_i964.DatabaseService>()),
    );
    gh.factory<_i130.WineSearchCubit>(
      () => _i130.WineSearchCubit(gh<_i44.WineRepository>()),
    );
    gh.lazySingleton<_i744.StorageService>(
      () => _i744.StorageService(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i342.WishlistCubit>(
      () => _i342.WishlistCubit(gh<_i135.WishlistRepository>()),
    );
    gh.lazySingleton<_i708.ArchiveCubit>(
      () => _i708.ArchiveCubit(gh<_i857.ArchiveRepository>()),
    );
    gh.factory<_i513.MainRepository>(
      () => _i513.MainRepositoryImpl(
        gh<_i964.DatabaseService>(),
        gh<_i1027.UCloudSyncService>(),
      ),
    );
    gh.factory<_i601.ProfileRepository>(
      () => _i601.ProfileRepositoryImpl(
        gh<_i964.DatabaseService>(),
        gh<_i1027.UCloudSyncService>(),
        gh<_i744.StorageService>(),
      ),
    );
    gh.factory<_i115.LoginCubit>(
      () => _i115.LoginCubit(
        gh<_i1027.UCloudSyncService>(),
        gh<_i964.DatabaseService>(),
        gh<_i744.StorageService>(),
      ),
    );
    gh.factory<_i427.MainCubit>(
      () => _i427.MainCubit(
        gh<_i513.MainRepository>(),
        gh<_i601.ProfileRepository>(),
      ),
    );
    gh.factory<_i115.ManageStorageCubit>(
      () => _i115.ManageStorageCubit(gh<_i601.ProfileRepository>()),
    );
    gh.factory<_i842.ProfileCubit>(
      () => _i842.ProfileCubit(gh<_i601.ProfileRepository>()),
    );
    return this;
  }
}

class _$InjectionModule extends _i465.InjectionModule {}
