import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wine_cellar/core/colors/app_colors.dart';
import 'package:wine_cellar/core/dependencies/get_it.dart';
import 'package:wine_cellar/core/router/app_router.dart';
import 'package:wine_cellar/core/style/app_text_style.dart';
import 'package:wine_cellar/core/widget/app_snackbar.dart';
import 'package:wine_cellar/core/widget/button.dart';
import 'package:wine_cellar/feature/profile_page/presentation/cubit/profile_cubit.dart';
import 'package:wine_cellar/feature/profile_page/presentation/cubit/profile_state.dart';

@RoutePage()
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ProfileCubit>()..loadProfile(),
      child: BlocConsumer<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state is ProfileUnauthenticated) {
            context.router.root.replaceAll([const LoginRoute()]);
          } else if (state is ProfileError) {
            AppSnackBar.show(context, message: state.message, isError: true);
          }
        },
        builder: (context, profileState) {
          final isSigningOut = profileState is ProfileLoading;

          final String username = profileState is ProfileLoaded ? profileState.username : '';
          final String initials = username.isNotEmpty ? username[0].toUpperCase() : 'W';

          return Scaffold(
            backgroundColor: AppColors.baseWhite,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text('Profile', style: AppTextStyles.h2),
              centerTitle: true,
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.lightBlue.withValues(alpha: 0.3),
                        border: Border.all(color: AppColors.lightBlue, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: AppTextStyles.h1.copyWith(fontSize: 40, color: AppColors.darkBlue),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (username.isNotEmpty)
                      Text(username, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 48),
                    AppButton(
                      text: 'Sign Out',
                      isSecondary: true,
                      icon: Icons.logout,
                      isLoading: isSigningOut,
                      onPressed: () => context.read<ProfileCubit>().signOut(),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
