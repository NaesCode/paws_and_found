import 'package:flutter/material.dart';
import '../../core/theme/wireframe_colors.dart';
import '../atoms/map_pin_badge.dart';

/// Data representation for a pin rendered on the map placeholder canvas.
class CanvasPinData {
  final String id;
  final String label; // 'M', 'S', 'F'
  final String status; // 'missing', 'stray', 'found'
  /// Normalized X coordinate between 0.0 and 1.0
  final double normalizedX;
  /// Normalized Y coordinate between 0.0 and 1.0
  final double normalizedY;

  const CanvasPinData({
    required this.id,
    required this.label,
    required this.status,
    required this.normalizedX,
    required this.normalizedY,
  });
}

/// A geographic map interface canvas organism in wireframe styling.
///
/// Draws a subtle grid pattern and street linework mimicking the SDD wireframe
/// layout, rendering interactive pins that notify when tapped.
///
/// Adheres to Atomic Design: dumb, stateless UI element relying purely on
/// passed properties and callbacks.
class MapPlaceholderCanvas extends StatelessWidget {
  final List<CanvasPinData> pins;
  final String? selectedPinId;
  final ValueChanged<String> onPinTap;
  final VoidCallback? onCanvasTap;

  const MapPlaceholderCanvas({
    super.key,
    required this.pins,
    this.selectedPinId,
    required this.onPinTap,
    this.onCanvasTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCanvasTap,
      behavior: HitTestBehavior.opaque,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          return Stack(
            children: [
              // 1. Grid & Street Linework Canvas
              CustomPaint(
                size: Size(width, height),
                painter: _MapWireframePainter(),
              ),

              // 2. Interactive Map Pins
              ...pins.map((pin) {
                final isSelected = pin.id == selectedPinId;
                // Calculate pixel position ensuring pins stay well inside bounds
                final x = pin.normalizedX * (width - 48);
                final y = pin.normalizedY * (height - 48);

                return Positioned(
                  left: x,
                  top: y,
                  child: MapPinBadge(
                    label: pin.label,
                    status: pin.status,
                    isSelected: isSelected,
                    onTap: () => onPinTap(pin.id),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

/// Custom painter for the wireframe map grid & major street linework.
class _MapWireframePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Background fill
    final bgPaint = Paint()..color = WireframeColors.mapCanvasBackground;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Grid lines paint
    final gridPaint = Paint()
      ..color = WireframeColors.gridLine
      ..strokeWidth = 1.0;

    const double gridSize = 44.0;
    // Draw vertical grid lines
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    // Draw horizontal grid lines
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Street linework paint (thicker cross streets from the wireframe)
    final streetPaint = Paint()
      ..color = WireframeColors.streetLine
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    // Major horizontal road
    final double midY = size.height * 0.42;
    canvas.drawLine(
      Offset(size.width * 0.12, midY),
      Offset(size.width * 0.88, midY),
      streetPaint,
    );

    // Major vertical road
    final double midX = size.width * 0.44;
    canvas.drawLine(
      Offset(midX, size.height * 0.28),
      Offset(midX, size.height * 0.62),
      streetPaint,
    );

    // Diagonal avenue intersecting
    canvas.drawLine(
      Offset(size.width * 0.28, size.height * 0.34),
      Offset(size.width * 0.70, size.height * 0.46),
      streetPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
