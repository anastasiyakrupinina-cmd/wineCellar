import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:wine_cellar/feature/dashboard_page/dashboard_page.dart';
import 'package:wine_cellar/feature/login_page/presentation/page/login_page.dart';
import 'package:wine_cellar/feature/main_page/presentation/page/main_page.dart';
import 'package:wine_cellar/feature/manage_storage_page/presentation/page/manage_storage.dart';
import 'package:wine_cellar/feature/profile_page/presentation/page/profile_page.dart';
import 'package:wine_cellar/feature/search_page/presentation/page/search_page.dart';
import 'package:wine_cellar/feature/search_page/presentation/page/wine_detail_page.dart';
import 'package:wine_cellar/feature/splash_page/splash_page.dart';
import 'package:wine_cellar/feature/wine/data/models/wine_model.dart';
import 'package:wine_cellar/feature/archive_page/presentation/page/archive_page.dart';
import 'package:wine_cellar/feature/wishlist_page/presentation/page/wishlist_page.dart';

part 'app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: SplashRoute.page, path: '/', initial: true),
    AutoRoute(page: LoginRoute.page, path: '/login'),
    AutoRoute(page: WineDetailRoute.page, path: '/wine-detail'),
AutoRoute(page: ManageStorageRoute.page, path: '/manage-storage'),
    AutoRoute(
      page: DashboardRoute.page,
      path: '/dashboard',
      children: [
        AutoRoute(page: MainRoute.page, path: 'main', initial: true),
        AutoRoute(page: SearchRoute.page, path: 'search'),
        AutoRoute(page: WishlistRoute.page, path: 'wishlist'),
        AutoRoute(page: ArchiveRoute.page, path: 'archive'),
        AutoRoute(page: ProfileRoute.page, path: 'profile'),
      ],
    ),
  ];
}

