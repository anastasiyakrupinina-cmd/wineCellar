import 'package:flutter/material.dart';
import 'package:wine_cellar/core/colors/app_colors.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isSecondary;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSecondary ? AppColors.lightGreen : AppColors.darkBlue,
          foregroundColor: isSecondary ? AppColors.textMain : AppColors.baseWhite,
          elevation: 0,
          shadowColor: AppColors.accentBlue.withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isSecondary ? AppColors.textMain : AppColors.baseWhite,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 10)],
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: isSecondary ? AppColors.textMain : AppColors.baseWhite,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
