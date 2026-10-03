import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._(); // Private constructor to prevent instantiation

  // ----------------------------------------------------
  // Nunito Sans
  // ----------------------------------------------------
  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'Nunito Sans',
    fontWeight: FontWeight.w700, // Bold
    fontSize: 61.0,
    height: 1.2, // 120% line-height
    color: AppColors.textPrimary,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: 'Nunito Sans',
    fontWeight: FontWeight.w400, // Regular
    fontSize: 49.0,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  // ----------------------------------------------------
  // Merriweather Sans
  // ----------------------------------------------------
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: 'Merriweather Sans',
    fontWeight: FontWeight.w400,
    fontSize: 39.0,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: 'Merriweather Sans',
    fontWeight: FontWeight.w400,
    fontSize: 31.0,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  // ----------------------------------------------------
  // Ek Mukta
  // ----------------------------------------------------
  static const TextStyle title = TextStyle(
    fontFamily: 'Ek Mukta',
    fontWeight: FontWeight.w400,
    fontSize: 25.0,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Ek Mukta',
    fontWeight: FontWeight.w400,
    fontSize: 20.0,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Ek Mukta',
    fontWeight: FontWeight.w400,
    fontSize: 16.0,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Ek Mukta',
    fontWeight: FontWeight.w400,
    fontSize: 13.0,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle label = TextStyle(
    fontFamily: 'Ek Mukta',
    fontWeight: FontWeight.w400,
    fontSize: 10.0,
    height: 1.2,
    color: AppColors.textPrimary,
  );
}
