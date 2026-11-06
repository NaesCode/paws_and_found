import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Legacy wireframe color palette mapped to official [AppColors] tokens
/// adhering to the clean, minimal veterinary design system.
class WireframeColors {
  WireframeColors._();

  // Canvas & Backgrounds
  static const Color background = AppColors.background;
  static const Color mapCanvasBackground = Color(0xFFF1F5F4);
  static const Color surface = AppColors.surface;
  static const Color surfaceSecondary = Color(0xFFF1F5F4);
  static const Color surfaceTertiary = Color(0xFFF8FAF9);

  // Linework, Dividers & Borders
  static const Color border = AppColors.border;
  static const Color borderLight = AppColors.borderLight;
  static const Color gridLine = Color(0xFFE2E8F0);
  static const Color streetLine = Color(0xFFCBD5E1);
  static const Color divider = AppColors.divider;

  // Brand Dark & Text Shades (Forest Teal & Dark Charcoal)
  static const Color primaryDark = AppColors.primary;
  static const Color secondarySlate = AppColors.text3;
  static const Color textPrimary = AppColors.darkCharcoal;
  static const Color textSecondary = AppColors.textSecondary;
  static const Color textMuted = AppColors.textMuted;

  // Form Inputs
  static const Color inputBackground = AppColors.inputBackground;
  static const Color inputBorder = AppColors.inputBorder;
  static const Color inputBorderFocused = AppColors.inputBorderFocused;
  static const Color inputHint = AppColors.inputHint;

  // Map Marker Pin Colors
  static const Color pinMissing = AppColors.statusMissing;
  static const Color pinStray = AppColors.statusStray;
  static const Color pinFoundBg = AppColors.primary;
  static const Color pinFoundBorder = AppColors.primary;
  static const Color pinSelectedGlow = Color(0x33428475);

  // Status Badge Colors
  static const Color badgeMissingBg = AppColors.statusMissing;
  static const Color badgeMissingText = Colors.white;
  static const Color badgeStrayBg = AppColors.statusStray;
  static const Color badgeStrayText = Colors.white;
  static const Color badgeFoundBg = AppColors.primary;
  static const Color badgeFoundBorder = AppColors.primary;
  static const Color badgeFoundText = Colors.white;
}
