import 'package:flutter/material.dart';
import '../../core/theme/wireframe_colors.dart';

/// A reusable placeholder container atom for wireframing media frames,
/// camera viewfinders, avatar circles, or charts during feature initializations.
///
/// Adheres to Atomic Design: dumb, stateless UI element relying purely on
/// passed properties.
class WireframeBox extends StatelessWidget {
  final double? width;
  final double? height;
  final IconData? icon;
  final String? label;
  final double borderRadius;
  final bool isCircle;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback? onTap;

  const WireframeBox({
    super.key,
    this.width,
    this.height,
    this.icon,
    this.label,
    this.borderRadius = 12.0,
    this.isCircle = false,
    this.backgroundColor = WireframeColors.surfaceSecondary,
    this.borderColor = WireframeColors.border,
    this.onTap,
  });

  /// Factory for an image/photo placeholder box (e.g. in Report or Feed cards)
  factory WireframeBox.image({
    Key? key,
    double size = 76.0,
    IconData icon = Icons.pets,
    VoidCallback? onTap,
  }) {
    return WireframeBox(
      key: key,
      width: size,
      height: size,
      icon: icon,
      onTap: onTap,
    );
  }

  /// Factory for a user profile avatar placeholder
  factory WireframeBox.avatar({
    Key? key,
    double radius = 32.0,
    IconData icon = Icons.person_outline_rounded,
    VoidCallback? onTap,
  }) {
    return WireframeBox(
      key: key,
      width: radius * 2,
      height: radius * 2,
      isCircle: true,
      icon: icon,
      onTap: onTap,
    );
  }

  /// Factory for a camera viewfinder canvas placeholder
  factory WireframeBox.viewfinder({
    Key? key,
    double height = 240.0,
    String label = 'Tap to capture photo',
    VoidCallback? onTap,
  }) {
    return WireframeBox(
      key: key,
      width: double.infinity,
      height: height,
      icon: Icons.camera_alt_outlined,
      label: label,
      borderRadius: 16.0,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
          border: Border.all(color: borderColor, width: 1.0),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              Icon(
                icon,
                size: (height != null && height! < 60) ? 20 : 28,
                color: WireframeColors.secondarySlate,
              ),
            if (icon != null && label != null) const SizedBox(height: 6),
            if (label != null)
              Text(
                label!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: WireframeColors.textSecondary,
                  fontSize: 12.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
