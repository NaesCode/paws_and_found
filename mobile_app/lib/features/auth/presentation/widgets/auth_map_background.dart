import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:paws_and_found/core/constants/app_assets.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';

/// Digital map image background with a sequential animated paw-step trail.
///
/// Designed for [LoginPage]: displays [AppAssets.authMapBg] softened with a
/// translucent clinical overlay, plus a curved trail of paw prints that appear
/// sequentially one after another.
class AuthMapBackground extends StatelessWidget {
  /// Progress from 0.0 to 1.0 controlling the sequential paw-step reveal.
  final Animation<double> pawProgress;

  const AuthMapBackground({
    super.key,
    required this.pawProgress,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Map image layer
          Image.asset(
            AppAssets.authMapBg,
            fit: BoxFit.cover,
          ),
          // Soft translucent veil so the brand emblem, text, and paws remain crisp
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFF3F9F7).withValues(alpha: 0.50),
                  const Color(0xFFF3F9F7).withValues(alpha: 0.40),
                  Colors.white.withValues(alpha: 0.65),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
          // Sequential paw-step trail layer
          AnimatedBuilder(
            animation: pawProgress,
            builder: (context, _) {
              return CustomPaint(
                painter: _PawTrailPainter(progress: pawProgress.value),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PawTrailPainter extends CustomPainter {
  final double progress;

  _PawTrailPainter({required this.progress});

  // Alternating left/right paw steps along a gentle curved rescue path
  static const List<_PawStep> _steps = [
    _PawStep(xFrac: 0.16, yFrac: 0.80, angle: -0.45, scale: 0.85),
    _PawStep(xFrac: 0.25, yFrac: 0.73, angle: -0.30, scale: 0.88),
    _PawStep(xFrac: 0.21, yFrac: 0.64, angle: -0.20, scale: 0.90),
    _PawStep(xFrac: 0.33, yFrac: 0.58, angle: 0.15, scale: 0.92),
    _PawStep(xFrac: 0.41, yFrac: 0.50, angle: 0.30, scale: 0.95),
    _PawStep(xFrac: 0.54, yFrac: 0.45, angle: 0.20, scale: 0.95),
    _PawStep(xFrac: 0.63, yFrac: 0.36, angle: -0.15, scale: 0.92),
    _PawStep(xFrac: 0.75, yFrac: 0.30, angle: -0.30, scale: 0.90),
    _PawStep(xFrac: 0.82, yFrac: 0.21, angle: -0.45, scale: 0.86),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final total = _steps.length;
    for (int i = 0; i < total; i++) {
      final start = i / total * 0.78;
      final end = (start + 0.22).clamp(0.0, 1.0);
      final localT = ((progress - start) / (end - start)).clamp(0.0, 1.0);
      if (localT <= 0.0) continue;

      final eased = Curves.easeOutBack.transform(localT).clamp(0.0, 1.15);
      final opacity = Curves.easeOut.transform(localT) * 0.35;

      final step = _steps[i];
      final center = Offset(size.width * step.xFrac, size.height * step.yFrac);

      _drawPaw(
        canvas,
        center: center,
        angle: step.angle,
        scale: step.scale * eased,
        color: AppColors.primary.withValues(alpha: opacity),
      );
    }
  }

  void _drawPaw(
    Canvas canvas, {
    required Offset center,
    required double angle,
    required double scale,
    required Color color,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    canvas.scale(scale);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Main paw pad
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 5), width: 18, height: 14),
      paint,
    );

    // 4 toe beans
    const toes = [
      Offset(-9.5, -5.5),
      Offset(-3.2, -9.5),
      Offset(3.2, -9.5),
      Offset(9.5, -5.5),
    ];
    for (final toe in toes) {
      canvas.save();
      canvas.translate(toe.dx, toe.dy);
      canvas.rotate(toe.dx * 0.03 * math.pi);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 5.5, height: 7.5),
        paint,
      );
      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PawTrailPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _PawStep {
  final double xFrac;
  final double yFrac;
  final double angle;
  final double scale;

  const _PawStep({
    required this.xFrac,
    required this.yFrac,
    required this.angle,
    required this.scale,
  });
}
