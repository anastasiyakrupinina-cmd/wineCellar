import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:file_picker/file_picker.dart';
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

enum _SignOutChoice { cancel, signOutOnly, saveAndSignOut }

@RoutePage()
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  bool get _isMobile => Platform.isAndroid || Platform.isIOS;

  Future<void> _saveDatabaseAs(BuildContext context) async {
    try {
      final bytes = await context.read<ProfileCubit>().getDatabaseFileBytes();
      if (!context.mounted) return;
      await FilePicker.saveFile(
        dialogTitle: 'Save WineCellar database as',
        fileName: 'winecellar.db',
        type: FileType.custom,
        allowedExtensions: ['db'],
        bytes: bytes,
      );
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.show(context, message: 'Could not save database: ${e.toString()}', isError: true);
      }
    }
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final cubit = context.read<ProfileCubit>();
    final needsSavePrompt = _isMobile && cubit.isLocalOnlyMode();

    if (needsSavePrompt) {
      final choice = await showDialog<_SignOutChoice>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('Save before signing out?'),
          content: const Text(
            'This database file lives inside the app and won\'t be reachable once you sign out. '
            'Save a copy first if you want to keep your changes.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(_SignOutChoice.cancel),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(_SignOutChoice.signOutOnly),
              child: const Text('Sign Out Without Saving'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(_SignOutChoice.saveAndSignOut),
              child: const Text('Save & Sign Out'),
            ),
          ],
        ),
      );
      if (choice == null || choice == _SignOutChoice.cancel) return;
      if (choice == _SignOutChoice.saveAndSignOut) {
        if (!context.mounted) return;
        await _saveDatabaseAs(context);
        if (!context.mounted) return;
      }
    }

    cubit.signOut();
  }

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
                      text: 'Save Database',
                      isSecondary: true,
                      icon: Icons.save_alt_rounded,
                      onPressed: () => _saveDatabaseAs(context),
                    ),
                    if (_isMobile) ...[
                      const SizedBox(height: 12),
                      Text(
                        'On Android and iOS, a database file you opened or created without syncing '
                        'to u:cloud lives inside the app. To access it from another app, save it '
                        'manually using the button above.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 12),
                    AppButton(
                      text: 'Sign Out',
                      isSecondary: true,
                      icon: Icons.logout,
                      isLoading: isSigningOut,
                      onPressed: () => _handleSignOut(context),
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
