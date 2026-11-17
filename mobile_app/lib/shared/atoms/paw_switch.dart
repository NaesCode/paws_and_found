import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// An atomic switch control designed with Paws and Found primary styling.
///
/// Adheres strictly to Atomic Design (lib/shared/atoms/).
/// Pure dumb component that relies exclusively on passed properties.
class PawSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final Color? inactiveTrackColor;

  const PawSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.inactiveTrackColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = activeColor ?? AppColors.primary;

    return Switch.adaptive(
      value: value,
      onChanged: onChanged,
      activeThumbColor: effectiveColor,
      activeTrackColor: effectiveColor.withValues(alpha: 0.35),
      inactiveTrackColor: inactiveTrackColor ?? AppColors.border,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
