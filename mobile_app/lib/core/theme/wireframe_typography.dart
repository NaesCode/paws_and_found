import 'package:flutter/material.dart';
import 'app_typography.dart';

/// Legacy wireframe typography definitions mapped to [AppTypography].
class WireframeTypography {
  WireframeTypography._();

  // Screen & Large Headers
  static const TextStyle screenTitle = AppTypography.screenTitle;
  static const TextStyle sectionHeader = AppTypography.sectionHeader;

  // Card Titles
  static const TextStyle cardTitle = AppTypography.cardTitle;

  // Body Content
  static const TextStyle body = AppTypography.body;

  // Subtitles & Metadata
  static const TextStyle subtitle = AppTypography.subtitle;
  static const TextStyle caption = AppTypography.caption;

  // Button Labels
  static const TextStyle buttonPrimary = AppTypography.buttonPrimary;
  static const TextStyle buttonOutlined = AppTypography.buttonOutlined;

  // Tags & Badges
  static const TextStyle tag = AppTypography.tag;
}
