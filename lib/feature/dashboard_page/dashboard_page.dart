import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:home_wine/core/colors/app_colors.dart';
import 'package:home_wine/core/router/app_router.dart';

@RoutePage()
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;

    return AutoTabsRouter(
      routes: const [MainRoute(), SearchRoute(), WishlistRoute(), ProfileRoute()],
      builder: (context, child) {
        final tabsRouter = AutoTabsRouter.of(context);

        return Scaffold(
          extendBody: !isDesktop,
          body: Row(
            children: [
              if (isDesktop) _buildSideRail(tabsRouter),

              Expanded(child: child),
            ],
          ),

          bottomNavigationBar: isDesktop ? null : _buildMobileBottomBar(tabsRouter),
        );
      },
    );
  }

  Widget _buildSideRail(TabsRouter tabsRouter) {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: AppColors.baseWhite,
        border: Border(right: BorderSide(color: AppColors.darkBlue.withOpacity(0.05))),
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),

          const Icon(Icons.wine_bar_rounded, color: AppColors.darkBlue, size: 32),
          const SizedBox(height: 80),

          _buildRailItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            isActive: tabsRouter.activeIndex == 0,
            onTap: () => tabsRouter.setActiveIndex(0),
          ),
          const SizedBox(height: 32),
          _buildRailItem(
            icon: Icons.search,
            activeIcon: Icons.search,
            isActive: tabsRouter.activeIndex == 1,
            onTap: () => tabsRouter.setActiveIndex(1),
          ),
          const SizedBox(height: 32),
          _buildRailItem(
            icon: Icons.bookmark_border,
            activeIcon: Icons.bookmark,
            isActive: tabsRouter.activeIndex == 2,
            onTap: () => tabsRouter.setActiveIndex(2),
          ),
          const SizedBox(height: 32),
          _buildRailItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            isActive: tabsRouter.activeIndex == 3,
            onTap: () => tabsRouter.setActiveIndex(3),
          ),

          const Spacer(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildRailItem({
    required IconData icon,
    required IconData activeIcon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.darkBlue.withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          isActive ? activeIcon : icon,
          color: isActive ? AppColors.darkBlue : AppColors.textSecondary,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildMobileBottomBar(TabsRouter tabsRouter) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.baseWhite.withOpacity(0.7),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkBlue.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Row(
              children: [
                _buildTabItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  isActive: tabsRouter.activeIndex == 0,
                  onTap: () => tabsRouter.setActiveIndex(0),
                ),
                _buildTabItem(
                  icon: Icons.search,
                  activeIcon: Icons.search,
                  isActive: tabsRouter.activeIndex == 1,
                  onTap: () => tabsRouter.setActiveIndex(1),
                ),
                _buildTabItem(
                  icon: Icons.bookmark_border,
                  activeIcon: Icons.bookmark,
                  isActive: tabsRouter.activeIndex == 2,
                  onTap: () => tabsRouter.setActiveIndex(2),
                ),
                _buildTabItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  isActive: tabsRouter.activeIndex == 3,
                  onTap: () => tabsRouter.setActiveIndex(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required IconData icon,
    required IconData activeIcon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              isActive ? activeIcon : icon,
              key: ValueKey(isActive),
              color: isActive ? AppColors.darkBlue : AppColors.textSecondary,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}
