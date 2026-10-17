import 'package:flutter/material.dart';
import '../../core/theme/wireframe_colors.dart';

/// An atom widget that paints the four L-shaped corner brackets
/// around the camera viewfinder canvas.
///
/// Adheres to Atomic Design: dumb, stateless UI element relying purely on
/// passed properties.
class CameraViewfinderBrackets extends StatelessWidget {
  final double bracketLength;
  final double strokeWidth;
  final Color color;
  final EdgeInsets padding;

  const CameraViewfinderBrackets({
    super.key,
    this.bracketLength = 26.0,
    this.strokeWidth = 2.5,
    this.color = WireframeColors.primaryDark,
    this.padding = const EdgeInsets.all(20.0),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: CustomPaint(
        painter: _BracketsPainter(
          bracketLength: bracketLength,
          strokeWidth: strokeWidth,
          color: color,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _BracketsPainter extends CustomPainter {
  final double bracketLength;
  final double strokeWidth;
  final Color color;

  _BracketsPainter({
    required this.bracketLength,
    required this.strokeWidth,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;

    // Top-Left ┌
    canvas.drawLine(const Offset(0, 0), Offset(bracketLength, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(0, bracketLength), paint);

    // Top-Right ┐
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - bracketLength, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, bracketLength), paint);

    // Bottom-Left └
    canvas.drawLine(Offset(0, size.height), Offset(bracketLength, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - bracketLength), paint);

    // Bottom-Right ┘
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - bracketLength, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - bracketLength), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
