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

  // ----------------------------------------------------
  // Profile Screen Typography
  // ----------------------------------------------------
  static const TextStyle profileTitle = TextStyle(
    fontFamily: 'Nunito Sans',
    fontWeight: FontWeight.w700,
    fontSize: 22.0,
    color: AppColors.text1,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: 'Nunito Sans',
    fontWeight: FontWeight.w700,
    fontSize: 20.0,
    color: AppColors.text2,
  );

  static const TextStyle userName = TextStyle(
    fontFamily: 'Nunito Sans',
    fontWeight: FontWeight.w700,
    fontSize: 16.0,
    color: AppColors.text2,
  );

  static const TextStyle userEmail = TextStyle(
    fontFamily: 'Nunito Sans',
    fontWeight: FontWeight.w400,
    fontSize: 13.0,
    color: AppColors.text2,
  );

  static const TextStyle userBio = TextStyle(
    fontFamily: 'Nunito Sans',
    fontWeight: FontWeight.w400,
    fontSize: 12.0,
    color: AppColors.text3,
  );

  static const TextStyle petName = TextStyle(
    fontFamily: 'Merriweather Sans',
    fontWeight: FontWeight.w700,
    fontSize: 14.0,
    color: AppColors.text2,
  );

  static const TextStyle statusBanner = TextStyle(
    fontFamily: 'Merriweather Sans',
    fontWeight: FontWeight.w700,
    fontSize: 10.0,
    letterSpacing: 4.0,
    color: AppColors.text1,
  );

  static const TextStyle petDescription = TextStyle(
    fontFamily: 'Ek Mukta',
    fontWeight: FontWeight.w400,
    fontSize: 11.0,
    height: 1.45,
    color: AppColors.text2,
  );

  static const TextStyle detailText = TextStyle(
    fontFamily: 'Ek Mukta',
    fontWeight: FontWeight.w400,
    fontSize: 12.0,
    color: AppColors.text3,
  );

  static const TextStyle pillText = TextStyle(
    fontFamily: 'Ek Mukta',
    fontWeight: FontWeight.w600,
    fontSize: 9.0,
    color: AppColors.text1,
  );

  // ----------------------------------------------------
  // Minimal & Clean Veterinary UI Typography
  // ----------------------------------------------------
  static const TextStyle screenTitle = TextStyle(
    fontFamily: 'Nunito Sans',
    fontWeight: FontWeight.w800,
    fontSize: 22.0,
    letterSpacing: -0.2,
    color: AppColors.darkCharcoal,
  );

  static const TextStyle sectionHeader = TextStyle(
    fontFamily: 'Nunito Sans',
    fontWeight: FontWeight.w700,
    fontSize: 18.0,
    letterSpacing: -0.1,
    color: AppColors.darkCharcoal,
  );

  static const TextStyle cardTitle = TextStyle(
    fontFamily: 'Nunito Sans',
    fontWeight: FontWeight.w700,
    fontSize: 16.0,
    color: AppColors.darkCharcoal,
  );

  static const TextStyle body = TextStyle(
    fontFamily: 'Ek Mukta',
    fontWeight: FontWeight.w400,
    fontSize: 13.5,
    height: 1.35,
    color: AppColors.darkCharcoal,
  );

  static const TextStyle subtitle = TextStyle(
    fontFamily: 'Ek Mukta',
    fontWeight: FontWeight.w400,
    fontSize: 12.5,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: 'Ek Mukta',
    fontWeight: FontWeight.w400,
    fontSize: 11.0,
    color: AppColors.textMuted,
  );

  static const TextStyle buttonPrimary = TextStyle(
    fontFamily: 'Nunito Sans',
    fontWeight: FontWeight.w700,
    fontSize: 14.0,
    letterSpacing: 0.2,
    color: Colors.white,
  );

  static const TextStyle buttonOutlined = TextStyle(
    fontFamily: 'Nunito Sans',
    fontWeight: FontWeight.w600,
    fontSize: 14.0,
    color: AppColors.primary,
  );

  static const TextStyle tag = TextStyle(
    fontFamily: 'Ek Mukta',
    fontWeight: FontWeight.w500,
    fontSize: 11.5,
    color: AppColors.darkCharcoal,
  );
}
