import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';

/// An atomic widget for rendering the official Paws and Found brand logo.
///
/// Adheres strictly to Atomic Design (lib/shared/atoms/).
/// Pure dumb component.
class AppLogo extends StatelessWidget {
  /// Overall diameter / dimension of the logo.
  final double size;

  /// Sizing / fitting strategy for the asset.
  final BoxFit fit;

  /// Optional semantic label for accessibility.
  final String? semanticsLabel;

  const AppLogo({
    super.key,
    this.size = 72.0,
    this.fit = BoxFit.contain,
    this.semanticsLabel = 'Paws and Found Logo',
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.appLogo,
      width: size,
      height: size,
      fit: fit,
      semanticLabel: semanticsLabel,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to app_launcher_icon.png if app_logo.png is not found
        return Image.asset(
          AppAssets.appLauncherIconPng,
          width: size,
          height: size,
          fit: fit,
          semanticLabel: semanticsLabel,
          errorBuilder: (_, _, _) => Icon(
            Icons.pets,
            size: size * 0.7,
            color: Colors.white,
          ),
        );
      },
    );
  }
}
