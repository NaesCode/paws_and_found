import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'app_logo.dart';

/// An atomic placeholder widget for the Paws and Found application logo.
///
/// Designed to hold the visual place of the finalized brand emblem across
/// splash, auth, navigation, and settings screens. Supports toggling between
/// the official vector SVG logo [AppLogo] and the procedural placeholder emblem.
///
/// Adheres strictly to Atomic Design (lib/shared/atoms/).
/// Pure dumb component.
class AppLogoPlaceholder extends StatelessWidget {
  /// Overall diameter / dimension of the logo emblem.
  final double size;

  /// Primary theme tint for the emblem icon and background gradient.
  final Color? color;

  /// Whether to display a subtle "[LOGO PLACEHOLDER]" tag beneath the icon.
  final bool showBadge;

  /// Whether to render the official vector SVG logo [AppLogo].
  final bool useSvg;

  const AppLogoPlaceholder({
    super.key,
    this.size = 72.0,
    this.color,
    this.showBadge = true,
    this.useSvg = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;
    final iconSize = size * 0.52;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (useSvg)
          AppLogo(size: size)
        else
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: effectiveColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(size * 0.28),
              border: Border.all(
                color: effectiveColor.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: effectiveColor.withValues(alpha: 0.15),
                  blurRadius: size * 0.2,
                  offset: Offset(0, size * 0.08),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Stylized primary paw emblem
                Icon(
                  Icons.pets_rounded,
                  size: iconSize,
                  color: effectiveColor,
                ),

                // Small rescue / cross badge overlay on top right
                Positioned(
                  top: size * 0.12,
                  right: size * 0.12,
                  child: Container(
                    width: size * 0.22,
                    height: size * 0.22,
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Icon(
                      Icons.location_on_rounded,
                      size: size * 0.12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (showBadge) ...[
          SizedBox(height: size * 0.08),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'LOGO PLACEHOLDER',
              style: TextStyle(
                fontFamily: 'Ek Mukta',
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
