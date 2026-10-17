import 'package:flutter/material.dart';
import '../../core/theme/wireframe_colors.dart';

/// A subtle border pill tag atom for animal traits (e.g., "Male", "Adult", "Golden").
///
/// Adheres to Atomic Design: dumb, stateless UI element relying purely on
/// passed properties.
class WireframeTag extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const WireframeTag({
    super.key,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: WireframeColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: WireframeColors.border, width: 1.0),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: WireframeColors.textSecondary,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
