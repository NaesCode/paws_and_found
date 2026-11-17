import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Section header typography atom for settings and configuration screens.
///
/// Adheres strictly to Atomic Design (lib/shared/atoms/).
/// Pure dumb component.
class SettingsSectionHeader extends StatelessWidget {
  final String title;
  final EdgeInsetsGeometry padding;

  const SettingsSectionHeader({
    super.key,
    required this.title,
    this.padding = const EdgeInsets.only(left: 4, bottom: 8, top: 16),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
