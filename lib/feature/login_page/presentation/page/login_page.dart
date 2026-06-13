import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wine_cellar/core/colors/app_colors.dart';
import 'package:wine_cellar/core/dependencies/get_it.dart';
import 'package:wine_cellar/core/router/app_router.dart';
import 'package:wine_cellar/core/style/app_text_style.dart';
import 'package:wine_cellar/core/validator/validators.dart';
import 'package:wine_cellar/core/widget/app_snackbar.dart';
import 'package:wine_cellar/core/widget/button.dart';
import 'package:wine_cellar/core/widget/text_field.dart';
import 'package:wine_cellar/feature/login_page/presentation/cubit/login_cubit.dart';
import 'package:wine_cellar/feature/login_page/presentation/cubit/login_state.dart';
import 'package:wine_cellar/feature/login_page/presentation/widget/line.dart';

@RoutePage()
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 600;

    return BlocProvider(
      create: (context) => getIt<LoginCubit>(),
      child: BlocConsumer<LoginCubit, LoginState>(
        listener: (context, state) {
          if (state is LoginSuccess) {
            context.router.replaceAll([const DashboardRoute()]);
          } else if (state is LoginFailure) {
            AppSnackBar.show(context, message: state.message, isError: true);
          }
        },
        builder: (context, state) {
          final isLoading = state is LoginLoading;

          return Scaffold(
            backgroundColor: AppColors.baseWhite,
            body: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return CustomPaint(painter: WineLinesPainter(progress: _controller.value));
                    },
                  ),
                ),
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 0 : 24.0, vertical: 24),
                      child: Container(
                        constraints: BoxConstraints(maxWidth: isDesktop ? 400 : double.infinity),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildAnimatedLogo(),
                            const SizedBox(height: 48),
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
                              decoration: BoxDecoration(
                                color: AppColors.baseWhite.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(32),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 40,
                                    offset: const Offset(0, 20),
                                  ),
                                ],
                                border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    AppTextField(
                                      label: 'University email',
                                      hint: 'email@univie.ac.at',
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      prefixIcon: Icons.alternate_email_rounded,
                                      validator: AppValidators.email,
                                    ),
                                    const SizedBox(height: 20),
                                    AppTextField(
                                      label: 'App password',
                                      hint: 'uCloud app password (not SSO)',
                                      controller: _passwordController,
                                      isPassword: true,
                                      prefixIcon: Icons.lock_outline_rounded,
                                      validator: AppValidators.password,
                                    ),
                                    const SizedBox(height: 24),
                                    AppButton(
                                      text: 'Sign In',
                                      isLoading: isLoading,
                                      onPressed: () {
                                        if (_formKey.currentState?.validate() ?? false) {
                                          context.read<LoginCubit>().login(
                                            _emailController.text.trim(),
                                            _passwordController.text,
                                          );
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      'Use your university email and an app password from uCloud.\n'
                                      'Generate it at ucloud.univie.ac.at → Settings → Security → App passwords.',
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.body.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.lightBlue.withValues(alpha: 0.4), AppColors.lightBlue.withValues(alpha: 0)],
                ),
              ),
            ),
            const Icon(Icons.wine_bar_rounded, size: 72, color: AppColors.darkBlue),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'WineCellar',
          style: AppTextStyles.h1.copyWith(
            letterSpacing: 12,
            fontSize: 24,
            fontWeight: FontWeight.w200,
            color: AppColors.darkBlue,
          ),
        ),
      ],
    );
  }
}
