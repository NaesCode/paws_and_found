import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Renders a blurred backdrop of the pet's photo.
///
/// Replaces the prototyping organic blob painter with an aesthetic, theme-consistent
/// ambient background derived from the actual pet photo, ensuring portrait and
/// landscape photos fill the tile naturally without harsh empty borders.
class PetBlurredBackground extends StatelessWidget {
  final String? photoUrl;
  final Widget? child;

  const PetBlurredBackground({
    super.key,
    this.photoUrl,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (photoUrl == null || photoUrl!.isEmpty) {
      return Container(
        color: AppColors.background2.withValues(alpha: 0.6),
        child: child,
      );
    }

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Blurred photo background
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Transform.scale(
              scale: 1.15, // Scale up slightly to prevent edge vignette
              child: Image.network(
                photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox(),
              ),
            ),
          ),

          // Subtle darkening overlay to maintain visual contrast and consistency
          Container(
            color: Colors.black.withValues(alpha: 0.15),
          ),

          ?child,
        ],
      ),
    );
  }
}

/// Legacy prototype painter preserved for backwards compatibility.
class PetBlobPainter extends CustomPainter {
  final Color color;

  const PetBlobPainter({this.color = AppColors.contrast1});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w * 0.20, h * 0.95);
    path.cubicTo(w * 0.50, h * 1.02, w * 0.85, h * 0.98, w * 0.92, h * 0.80);
    path.cubicTo(w * 0.98, h * 0.60, w * 0.95, h * 0.35, w * 0.82, h * 0.22);
    path.cubicTo(w * 0.70, h * 0.08, w * 0.35, h * 0.12, w * 0.18, h * 0.30);
    path.cubicTo(w * 0.04, h * 0.45, w * 0.05, h * 0.75, w * 0.20, h * 0.95);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
