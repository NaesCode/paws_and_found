import 'package:flutter/material.dart';
import '../../core/theme/wireframe_colors.dart';

/// A reusable wireframe card container organism for displaying structured content
/// across initialized screens (e.g., Feed cards, Profile logs, Recovery steps).
///
/// Adheres to Atomic Design: dumb, stateless UI element relying purely on
/// passed properties.
class WireframeCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final VoidCallback? onTap;

  const WireframeCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
    this.borderRadius = 16.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: WireframeColors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: WireframeColors.borderLight, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
