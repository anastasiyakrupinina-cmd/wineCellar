import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_wine/core/colors/app_colors.dart';
import 'package:home_wine/core/router/app_router.dart';
import 'package:home_wine/core/style/app_text_style.dart';
import 'package:home_wine/feature/main_page/presentation/cubit/main_cubit.dart';
import 'package:home_wine/feature/main_page/presentation/cubit/main_state.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onFilterPressed;
  final VoidCallback onAddPressed; 

  const MainAppBar({super.key, required this.onFilterPressed, required this.onAddPressed});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.baseWhite.withOpacity(0.8),
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        onPressed: () => context.router.push(const ManageStorageRoute()),
        icon: const Icon(Icons.inventory_2_outlined, color: AppColors.darkBlue, size: 28),
      ),
      title: BlocBuilder<MainCubit, MainState>(
        builder: (context, state) {
          int count = (state is MainLoaded) ? state.wines.fold(0, (sum, w) => sum + w.quantity) : 0;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My Cellar', style: AppTextStyles.h1.copyWith(fontSize: 28)),
              Text('$count bottles curated', style: AppTextStyles.caption),
            ],
          );
        },
      ),
      actions: [
        
        IconButton(
          onPressed: onFilterPressed,
          icon: const Icon(Icons.tune_rounded, color: AppColors.darkBlue, size: 26),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
