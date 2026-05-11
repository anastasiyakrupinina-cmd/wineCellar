import 'package:flutter/material.dart';
import 'package:home_wine/core/colors/app_colors.dart';
import 'package:home_wine/core/style/app_text_style.dart';

class AppSnackBar {
  static void show(BuildContext context, {required String message, bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: AppColors.baseWhite),
              const SizedBox(width: 12),
              Expanded(
                child: Text(message, style: AppTextStyles.body.copyWith(color: AppColors.baseWhite)),
              ),
            ],
          ),
          backgroundColor: isError ? AppColors.error : AppColors.darkBlue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          duration: const Duration(seconds: 3),
        ),
      );
  }
}
