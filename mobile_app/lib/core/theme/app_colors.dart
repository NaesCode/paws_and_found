import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // Main Background
  static const Color background = Color(0xFFFFFFFF);
  static const Color background1 = Color(0xFFFFFFFF);
  static const Color background2 = Color(0xFFD9D9D9);
  
  // Core Palette
  static const Color primary = Color(0xFF428475); // Teal / Green
  static const Color darkCharcoal = Color(0xFF2C302E);
  static const Color accentOrange = Color(0xFFFF8552);
  static const Color contrast1 = Color(0xFFFF8552);
  static const Color accentMaroon = Color(0xFF80383A);
  static const Color contrast2 = Color(0xFF80383A);

  // Common Text Colors
  static const Color textPrimary = Color(0xFF000000);
  static const Color text1 = Color(0xFFFFFFFF);
  static const Color text2 = Color(0xFF000000);
  static const Color text3 = Color(0xFF827E7E);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Surface & Clinical Clean Tones
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF8FAF9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color divider = Color(0xFFE2E8F0);

  // Form Inputs
  static const Color inputBackground = Color(0xFFFFFFFF);
  static const Color inputBorder = Color(0xFFE2E8F0);
  static const Color inputBorderFocused = Color(0xFF428475);
  static const Color inputHint = Color(0xFF94A3B8);

  // Status Alerts (Veterinary / Animal Alert System)
  static const Color statusMissing = accentMaroon; // #80383A
  static const Color statusStray = accentOrange;   // #FF8552
  static const Color statusFound = primary;        // #428475
  static const Color statusSafe = Color(0xFF059669);
}
