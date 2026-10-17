import 'package:flutter/material.dart';

/// Centralized wireframe color palette for initializing new UI screens
/// before final brand styling is applied.
///
/// Provides cool grays, slate, and charcoal neutrals adhering to the
/// Software Design Document (SDD) wireframe aesthetics.
class WireframeColors {
  WireframeColors._();

  // Canvas & Backgrounds
  static const Color background = Color(0xFFF8F9FA);
  static const Color mapCanvasBackground = Color(0xFFF1F3F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSecondary = Color(0xFFECEFF3);
  static const Color surfaceTertiary = Color(0xFFF1F3F6);

  // Linework, Dividers & Borders
  static const Color border = Color(0xFFCBD5E1);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color gridLine = Color(0xFFE2E6EA);
  static const Color streetLine = Color(0xFFCFD6DE);
  static const Color divider = Color(0xFFE2E8F0);

  // Wireframe Dark & Slate Shades
  static const Color primaryDark = Color(0xFF2C3444);
  static const Color secondarySlate = Color(0xFF8692A6);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Form Inputs
  static const Color inputBackground = Color(0xFFFFFFFF);
  static const Color inputBorder = Color(0xFFCBD5E1);
  static const Color inputBorderFocused = Color(0xFF2C3444);
  static const Color inputHint = Color(0xFF94A3B8);

  // Map Marker Pin Colors
  static const Color pinMissing = Color(0xFF2C3444);
  static const Color pinStray = Color(0xFF8692A6);
  static const Color pinFoundBg = Color(0xFFFFFFFF);
  static const Color pinFoundBorder = Color(0xFF2C3444);
  static const Color pinSelectedGlow = Color(0x332C3444);

  // Status Badge Colors
  static const Color badgeMissingBg = Color(0xFF2C3444);
  static const Color badgeMissingText = Color(0xFFFFFFFF);
  static const Color badgeStrayBg = Color(0xFF8692A6);
  static const Color badgeStrayText = Color(0xFFFFFFFF);
  static const Color badgeFoundBg = Color(0xFFFFFFFF);
  static const Color badgeFoundBorder = Color(0xFF2C3444);
  static const Color badgeFoundText = Color(0xFF2C3444);
}
