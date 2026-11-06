import 'package:flutter/material.dart';
import 'app_theme.dart';

export 'wireframe_colors.dart';
export 'wireframe_typography.dart';

/// Legacy wireframe theme mapped directly to the production [AppTheme.light].
class WireframeTheme {
  WireframeTheme._();

  /// Returns [AppTheme.light] configured for clinical, minimal branding.
  static ThemeData get themeData => AppTheme.light;
}
