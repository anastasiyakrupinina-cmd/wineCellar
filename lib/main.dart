import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_wine/app_settings_cubit.dart';
import 'package:home_wine/core/dependencies/get_it.dart';
import 'package:home_wine/core/router/app_router.dart';
import 'package:home_wine/core/storage/storage_service.dart';
import 'package:home_wine/core/sync/ucloud_sync_service.dart';
import 'package:home_wine/core/theme/app_theme.dart';

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
      onPause: _onAppBackground,   // Android: app goes to background
      onDetach: _onAppBackground,  // Android app is being closed
      onHide: _onAppBackground,    // Windows: window minimized or hidden
    );
  }

  Future<void> _onAppBackground() async {
    if (kIsWeb) return;
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
    return BlocProvider(
      create: (_) => AppSettingsCubit(getIt<StorageService>()),
      child: MaterialApp.router(
        title: 'Home Wine',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        routerConfig: _appRouter.config(navigatorObservers: () => [AutoRouteObserver()]),
      ),
    );
  }
}
