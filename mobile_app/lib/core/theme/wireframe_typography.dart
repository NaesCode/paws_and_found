import 'package:flutter/material.dart';
import 'wireframe_colors.dart';

/// Centralized typography definitions for the wireframe design system.
///
/// Ensures clear information hierarchy and consistent typography
/// across all prototyping screens.
class WireframeTypography {
  WireframeTypography._();

  // Screen & Large Headers
  static const TextStyle screenTitle = TextStyle(
    color: WireframeColors.textPrimary,
    fontSize: 22.0,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
  );

  static const TextStyle sectionHeader = TextStyle(
    color: WireframeColors.textPrimary,
    fontSize: 18.0,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
  );

  // Card Titles
  static const TextStyle cardTitle = TextStyle(
    color: WireframeColors.textPrimary,
    fontSize: 16.0,
    fontWeight: FontWeight.w700,
  );

  // Body Content
  static const TextStyle body = TextStyle(
    color: WireframeColors.textPrimary,
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    height: 1.35,
  );

  // Subtitles & Metadata
  static const TextStyle subtitle = TextStyle(
    color: WireframeColors.textSecondary,
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle caption = TextStyle(
    color: WireframeColors.textMuted,
    fontSize: 11.0,
    fontWeight: FontWeight.w400,
  );

  // Button Labels
  static const TextStyle buttonPrimary = TextStyle(
    color: Colors.white,
    fontSize: 14.0,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );

  static const TextStyle buttonOutlined = TextStyle(
    color: WireframeColors.textPrimary,
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
  );

  // Tags & Badges
  static const TextStyle tag = TextStyle(
    color: WireframeColors.textSecondary,
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
  );
}
