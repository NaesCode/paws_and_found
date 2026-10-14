import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// CustomPainter rendering an organic, asymmetrical rounded blob in contrast1 (Orange)
/// to serve as the vibrant backdrop behind pet photos.
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

    // Organic blob anchored toward the bottom and slightly rounded at the corners
    path.moveTo(w * 0.20, h * 0.95);
    // Bottom curve to bottom-right
    path.cubicTo(w * 0.50, h * 1.02, w * 0.85, h * 0.98, w * 0.92, h * 0.80);
    // Right curve upward
    path.cubicTo(w * 0.98, h * 0.60, w * 0.95, h * 0.35, w * 0.82, h * 0.22);
    // Top curve
    path.cubicTo(w * 0.70, h * 0.08, w * 0.35, h * 0.12, w * 0.18, h * 0.30);
    // Left curve downward back to start
    path.cubicTo(w * 0.04, h * 0.45, w * 0.05, h * 0.75, w * 0.20, h * 0.95);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

