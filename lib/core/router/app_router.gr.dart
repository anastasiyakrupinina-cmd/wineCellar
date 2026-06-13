// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [ArchivePage]
class ArchiveRoute extends PageRouteInfo<void> {
  const ArchiveRoute({List<PageRouteInfo>? children})
    : super(ArchiveRoute.name, initialChildren: children);

  static const String name = 'ArchiveRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ArchivePage();
    },
  );
}

/// generated route for
/// [DashboardPage]
class DashboardRoute extends PageRouteInfo<void> {
  const DashboardRoute({List<PageRouteInfo>? children})
    : super(DashboardRoute.name, initialChildren: children);

  static const String name = 'DashboardRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const DashboardPage();
    },
  );
}

/// generated route for
/// [LoginPage]
class LoginRoute extends PageRouteInfo<void> {
  const LoginRoute({List<PageRouteInfo>? children})
    : super(LoginRoute.name, initialChildren: children);

  static const String name = 'LoginRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const LoginPage();
    },
  );
}

/// generated route for
/// [MainPage]
class MainRoute extends PageRouteInfo<void> {
  const MainRoute({List<PageRouteInfo>? children})
    : super(MainRoute.name, initialChildren: children);

  static const String name = 'MainRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const MainPage();
    },
  );
}

/// generated route for
/// [ManageStoragePage]
class ManageStorageRoute extends PageRouteInfo<void> {
  const ManageStorageRoute({List<PageRouteInfo>? children})
    : super(ManageStorageRoute.name, initialChildren: children);

  static const String name = 'ManageStorageRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ManageStoragePage();
    },
  );
}

/// generated route for
/// [ProfilePage]
class ProfileRoute extends PageRouteInfo<void> {
  const ProfileRoute({List<PageRouteInfo>? children})
    : super(ProfileRoute.name, initialChildren: children);

  static const String name = 'ProfileRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ProfilePage();
    },
  );
}

/// generated route for
/// [SearchPage]
class SearchRoute extends PageRouteInfo<void> {
  const SearchRoute({List<PageRouteInfo>? children})
    : super(SearchRoute.name, initialChildren: children);

  static const String name = 'SearchRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SearchPage();
    },
  );
}

/// generated route for
/// [SplashPage]
class SplashRoute extends PageRouteInfo<void> {
  const SplashRoute({List<PageRouteInfo>? children})
    : super(SplashRoute.name, initialChildren: children);

  static const String name = 'SplashRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SplashPage();
    },
  );
}

/// generated route for
/// [WishlistPage]
class WishlistRoute extends PageRouteInfo<void> {
  const WishlistRoute({List<PageRouteInfo>? children})
    : super(WishlistRoute.name, initialChildren: children);

  static const String name = 'WishlistRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const WishlistPage();
    },
  );
}

/// generated route for
/// [WineDetailPage]
class WineDetailRoute extends PageRouteInfo<WineDetailRouteArgs> {
  WineDetailRoute({Key? key, WineModel? wine, bool readOnly = false, List<PageRouteInfo>? children})
    : super(
        WineDetailRoute.name,
        args: WineDetailRouteArgs(key: key, wine: wine, readOnly: readOnly),
        initialChildren: children,
      );

  static const String name = 'WineDetailRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<WineDetailRouteArgs>(
        orElse: () => const WineDetailRouteArgs(),
      );
      return WineDetailPage(key: args.key, wine: args.wine, readOnly: args.readOnly);
    },
  );
}

class WineDetailRouteArgs {
  const WineDetailRouteArgs({this.key, this.wine, this.readOnly = false});

  final Key? key;

  final WineModel? wine;

  final bool readOnly;

  @override
  String toString() {
    return 'WineDetailRouteArgs{key: $key, wine: $wine, readOnly: $readOnly}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WineDetailRouteArgs) return false;
    return key == other.key && wine == other.wine && readOnly == other.readOnly;
  }

  @override
  int get hashCode => key.hashCode ^ wine.hashCode ^ readOnly.hashCode;
}
