import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wine_cellar/core/colors/app_colors.dart';

class AppTextStyles {
  static TextStyle h1 = GoogleFonts.montserrat(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.darkBlue,
    letterSpacing: -0.5,
  );

  static TextStyle h2 = GoogleFonts.montserrat(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.darkBlue,
  );

  static TextStyle body = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.darkBlue.withValues(alpha: 0.9),
  );

  static TextStyle caption = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.darkBlue.withValues(alpha: 0.6),
  );

  static TextStyle button = GoogleFonts.montserrat(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.baseWhite,
  );

  static TextStyle accent = GoogleFonts.montserrat(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.lightBlue,
  );
}
