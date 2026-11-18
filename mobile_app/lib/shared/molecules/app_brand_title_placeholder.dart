import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../atoms/app_logo_placeholder.dart';

/// Layout orientation for the brand placeholder header.
enum BrandLayoutMode { vertical, horizontal }

/// Molecule combining the logo emblem placeholder with the brand name and tagline.
///
/// Designed as a drop-in component that can be replaced in one place once the
/// finalized typography mark and vector logo are ready.
///
/// Adheres strictly to Atomic Design (lib/shared/molecules/).
/// Pure dumb component.
class AppBrandTitlePlaceholder extends StatelessWidget {
  final BrandLayoutMode layoutMode;
  final double logoSize;
  final bool showBadge;
  final String title;
  final String? subtitle;
  final Color? titleColor;

  const AppBrandTitlePlaceholder({
    super.key,
    this.layoutMode = BrandLayoutMode.vertical,
    this.logoSize = 72.0,
    this.showBadge = true,
    this.title = 'Paws and Found',
    this.subtitle = 'Community Lost & Found Animal Recovery',
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTitleColor = titleColor ?? AppColors.darkCharcoal;

    if (layoutMode == BrandLayoutMode.horizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppLogoPlaceholder(
            size: logoSize,
            showBadge: false,
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Nunito Sans',
                  fontSize: 20.0,
                  fontWeight: FontWeight.w800,
                  color: effectiveTitleColor,
                  letterSpacing: -0.3,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontFamily: 'Ek Mukta',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ],
      );
    }

    // Default Vertical Layout (ideal for Login, Onboarding, and Splash screens)
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppLogoPlaceholder(
          size: logoSize,
          showBadge: showBadge,
        ),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Nunito Sans',
            fontSize: 28.0,
            fontWeight: FontWeight.w800,
            color: effectiveTitleColor,
            letterSpacing: -0.5,
            height: 1.15,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Ek Mukta',
                fontSize: 13.0,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
