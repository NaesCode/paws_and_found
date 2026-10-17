import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'wireframe_colors.dart';
import 'wireframe_typography.dart';

export 'wireframe_colors.dart';
export 'wireframe_typography.dart';

/// Dedicated wireframe theming toolkit for initializing new UI screens
/// before applying official brand styling.
///
/// Keeps production brand styling ([AppTheme.light]) untouched while giving
/// developers a ready-to-use slate/charcoal wireframe design system for
/// future feature initializations (e.g., Feed, Camera/Report, Recovery Pipeline).
///
/// Usage for a new wireframe screen:
/// ```dart
/// @override
/// Widget build(BuildContext context) {
///   return Theme(
///     data: WireframeTheme.themeData,
///     child: Scaffold(...),
///   );
/// }
/// ```
class WireframeTheme {
  WireframeTheme._();

  /// Pre-configured wireframe [ThemeData] for wrapping prototype / initialization pages.
  static ThemeData get themeData => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: WireframeColors.background,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: WireframeColors.primaryDark,
          onPrimary: Colors.white,
          secondary: WireframeColors.secondarySlate,
          onSecondary: Colors.white,
          surface: WireframeColors.surface,
          onSurface: WireframeColors.textPrimary,
          error: Color(0xFFDC2626),
          onError: Colors.white,
          outline: WireframeColors.border,
        ),

        // ── AppBar (Clean white wireframe app bar) ───────────────────────────
        appBarTheme: const AppBarTheme(
          backgroundColor: WireframeColors.surface,
          foregroundColor: WireframeColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: WireframeTypography.screenTitle,
          iconTheme: IconThemeData(color: WireframeColors.primaryDark),
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
        ),

        // ── Card ─────────────────────────────────────────────────────────────
        cardTheme: CardThemeData(
          color: WireframeColors.surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: WireframeColors.borderLight, width: 1.0),
          ),
        ),

        // ── Form Inputs ──────────────────────────────────────────────────────
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: WireframeColors.inputBackground,
          hintStyle: const TextStyle(
            color: WireframeColors.inputHint,
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: WireframeColors.inputBorder, width: 1.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: WireframeColors.inputBorder, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: WireframeColors.inputBorderFocused, width: 1.8),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.2),
          ),
        ),

        // ── Buttons ──────────────────────────────────────────────────────────
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: WireframeColors.primaryDark,
            foregroundColor: Colors.white,
            elevation: 0,
            textStyle: WireframeTypography.buttonPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: WireframeColors.textPrimary,
            backgroundColor: WireframeColors.surface,
            elevation: 0,
            textStyle: WireframeTypography.buttonOutlined,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            side: const BorderSide(color: WireframeColors.border, width: 1.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),

        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: WireframeColors.primaryDark,
            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
          ),
        ),

        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: WireframeColors.primaryDark,
          foregroundColor: Colors.white,
          elevation: 2,
        ),

        // ── Divider ──────────────────────────────────────────────────────────
        dividerTheme: const DividerThemeData(
          color: WireframeColors.divider,
          thickness: 1.0,
          space: 1.0,
        ),
      );
}
