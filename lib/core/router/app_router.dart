import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:home_wine/feature/dashboard_page/dashboard_page.dart';
import 'package:home_wine/feature/login_page/presentation/page/login_page.dart';
import 'package:home_wine/feature/main_page/presentation/page/main_page.dart';
import 'package:home_wine/feature/manage_storage_page/presentation/page/manage_storage.dart';
import 'package:home_wine/feature/profile_page/presentation/page/profile_page.dart';
import 'package:home_wine/feature/search_page/presentation/page/search_page.dart';
import 'package:home_wine/feature/search_page/presentation/page/wine_detail_page.dart';
import 'package:home_wine/feature/setting_page/presentation/page/settings_page.dart';
import 'package:home_wine/feature/splash_page/splash_page.dart';
import 'package:home_wine/feature/wine/data/models/wine_model.dart';
import 'package:home_wine/feature/wishlist_page/presentation/page/wishlist_page.dart';

part 'app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: SplashRoute.page, path: '/', initial: true),
    AutoRoute(page: LoginRoute.page, path: '/login'),
    AutoRoute(page: WineDetailRoute.page, path: '/wine-detail'),
    AutoRoute(page: SettingsRoute.page, path: '/settings'),
    AutoRoute(page: ManageStorageRoute.page, path: '/manage-storage'),
    AutoRoute(
      page: DashboardRoute.page,
      path: '/dashboard',
      children: [
        AutoRoute(page: MainRoute.page, path: 'main', initial: true),
        AutoRoute(page: SearchRoute.page, path: 'search'),
        AutoRoute(page: WishlistRoute.page, path: 'wishlist'),
        AutoRoute(page: ProfileRoute.page, path: 'profile'),
      ],
    ),
  ];
}
// dart run build_runner build --delete-conflicting-outputs
