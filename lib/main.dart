import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wine_cellar/app_settings_cubit.dart';
import 'package:wine_cellar/core/dependencies/get_it.dart';
import 'package:wine_cellar/core/router/app_router.dart';
import 'package:wine_cellar/core/storage/storage_service.dart';
import 'package:wine_cellar/core/sync/ucloud_sync_service.dart';
import 'package:wine_cellar/core/theme/app_theme.dart';
import 'package:wine_cellar/feature/archive_page/presentation/cubit/archive_cubit.dart';
import 'package:wine_cellar/feature/wishlist_page/presentation/cubit/wishlist_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppRouter _appRouter;
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _appRouter = AppRouter();
    _lifecycleListener = AppLifecycleListener(
      onPause: _onAppBackground,   // Android goes to background
      onDetach: _onAppBackground,  // Android app is being closed
      onHide: _onAppBackground,    // Windows minimized or hidden
    );
  }

  Future<void> _onAppBackground() async {
    print('[Lifecycle] _onAppBackground triggered');
    final sync = getIt<UCloudSyncService>();
    final hasCreds = await sync.hasCredentials();
    print('[Lifecycle] hasCredentials: $hasCreds');
    if (hasCreds) {
      print('[Lifecycle] Starting syncOnClose...');
      await sync.syncOnClose();
      print('[Lifecycle] syncOnClose complete');
    }
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AppSettingsCubit(getIt<StorageService>())),
        BlocProvider.value(value: getIt<WishlistCubit>()),
        BlocProvider.value(value: getIt<ArchiveCubit>()),
      ],
      child: MaterialApp.router(
        title: 'Wine Cellar',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        routerConfig: _appRouter.config(navigatorObservers: () => [AutoRouteObserver()]),
      ),
    );
  }
}
