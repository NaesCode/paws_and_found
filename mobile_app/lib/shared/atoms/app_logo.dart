import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/app_assets.dart';

/// An atomic widget for rendering the official Paws and Found vector logo.
///
/// Adheres strictly to Atomic Design (lib/shared/atoms/).
/// Pure dumb component.
class AppLogo extends StatelessWidget {
  /// Overall diameter / dimension of the logo.
  final double size;

  /// Sizing / fitting strategy for the vector asset.
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
    return SvgPicture.asset(
      AppAssets.pawsLogoSvg,
      width: size,
      height: size,
      fit: fit,
      semanticsLabel: semanticsLabel,
    );
  }
}
