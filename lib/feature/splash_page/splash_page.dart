import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:wine_cellar/core/colors/app_colors.dart';
import 'package:wine_cellar/core/database/database_service.dart';
import 'package:wine_cellar/core/dependencies/get_it.dart';
import 'package:wine_cellar/core/router/app_router.dart';
import 'package:wine_cellar/core/style/app_text_style.dart';
import 'package:wine_cellar/core/sync/ucloud_sync_service.dart' show UCloudSyncService, SyncOutcome;
import 'package:wine_cellar/feature/login_page/presentation/widget/line.dart';
import 'package:wine_cellar/feature/wishlist_page/presentation/cubit/wishlist_cubit.dart';

@RoutePage()
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 10))
      ..repeat(reverse: true);
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final hasCreds = await getIt<UCloudSyncService>().hasCredentials();
    if (!mounted) return;

    if (hasCreds) {
      await getIt<DatabaseService>().init();
      await getIt<WishlistCubit>().load();
      final outcome = await getIt<UCloudSyncService>().syncOnStart();
      if (!mounted) return;
      if (outcome == SyncOutcome.conflict) {
        final keepLocal = await _showConflictDialog();
        if (!mounted) return;
        if (keepLocal) {
          await getIt<UCloudSyncService>().uploadDb();
        } else {
          await getIt<UCloudSyncService>().resolveWithRemote();
        }
        if (!mounted) return;
      }
      context.router.replace(const DashboardRoute());
    } else {
      context.router.replace(const LoginRoute());
    }
  }

  Future<bool> _showConflictDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Sync conflict'),
        content: const Text(
          'You have local changes that were not uploaded, but uCloud also has newer data. Which version do you want to keep?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep uCloud'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Keep mine'),
          ),
        ],
      ),
    );
    return result ?? true;
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.baseWhite,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (context, child) {
                return CustomPaint(painter: WineLinesPainter(progress: _bgController.value));
              },
            ),
          ),
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeOutExpo,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(scale: 0.8 + (0.2 * value), child: child),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.lightBlue.withValues(alpha: 0.5),
                              AppColors.lightBlue.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                      const Icon(Icons.wine_bar_rounded, size: 80, color: AppColors.darkBlue),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'WineCellar',
                    style: AppTextStyles.h1.copyWith(
                      letterSpacing: 12,
                      fontSize: 32,
                      fontWeight: FontWeight.w200,
                      color: AppColors.darkBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
