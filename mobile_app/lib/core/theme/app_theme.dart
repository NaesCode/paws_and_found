import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

/// Centralized Material 3 theme for Paws and Found.
///
/// All [AppBar] widgets in the app automatically inherit from [appBarTheme]
/// without needing any per-page style overrides.
///
/// Usage in main.dart:
///   theme: AppTheme.light,
class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
    scaffoldBackgroundColor: AppColors.background,

    // ── AppBar ────────────────────────────────────────────────────────────
    // Every Scaffold's AppBar across the whole app will use these defaults.
    // Individual pages only need to set `title:` — no manual color/style needed.
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white, // applies to icons + back button
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Nunito Sans',
        fontWeight: FontWeight.w700,
        fontSize: 22.0,
        color: Colors.white,
      ),
      iconTheme: IconThemeData(color: Colors.white),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // white status bar icons
      ),
    ),

    // ── Navigation Bar ────────────────────────────────────────────────────
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.primary.withValues(alpha: 0.15),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(
          fontFamily: 'Ek Mukta',
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
