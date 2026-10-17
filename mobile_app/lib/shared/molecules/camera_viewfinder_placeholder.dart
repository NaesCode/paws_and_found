import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/theme/wireframe_colors.dart';
import '../atoms/camera_viewfinder_brackets.dart';

/// A camera viewfinder placeholder molecule for the Animal Report Creation flow.
///
/// Implements SDD Screen 05 (Camera & Report):
/// - Native viewfinder canvas placeholder with corner brackets (┌ ┐ └ ┘)
/// - Center dashed target box with camera icon
/// - "Gallery" selection button in the bottom-left corner
/// - Preview display when an image is captured or selected
///
/// Adheres to Atomic Design: dumb, stateless UI element relying purely on
/// passed properties and callbacks.
class CameraViewfinderPlaceholder extends StatelessWidget {
  final double height;
  final Uint8List? imageBytes;
  final VoidCallback? onCaptureTap;
  final VoidCallback? onGalleryTap;
  final VoidCallback? onRetakeTap;

  const CameraViewfinderPlaceholder({
    super.key,
    this.height = 260.0,
    this.imageBytes,
    this.onCaptureTap,
    this.onGalleryTap,
    this.onRetakeTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasImage = imageBytes != null;

    return Container(
      width: double.infinity,
      height: height,
      color: WireframeColors.surfaceSecondary,
      child: Stack(
        children: [
          // 1. If an image has been captured/picked, show preview
          if (hasImage)
            Positioned.fill(
              child: Image.memory(
                imageBytes!,
                fit: BoxFit.cover,
              ),
            ),

          // 2. Corner Framing Brackets
          const Positioned.fill(
            child: CameraViewfinderBrackets(
              bracketLength: 28.0,
              strokeWidth: 2.5,
              padding: EdgeInsets.all(22.0),
            ),
          ),

          // 3. Center Target (Dashed container + camera icon)
          if (!hasImage)
            Center(
              child: GestureDetector(
                onTap: onCaptureTap,
                behavior: HitTestBehavior.opaque,
                child: CustomPaint(
                  painter: _DashedRRectPainter(
                    color: WireframeColors.secondarySlate,
                    strokeWidth: 2.0,
                    radius: 20.0,
                  ),
                  child: Container(
                    width: 104,
                    height: 104,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      size: 40,
                      color: WireframeColors.primaryDark,
                    ),
                  ),
                ),
              ),
            ),

          // 4. "Gallery" Button in Bottom-Left
          Positioned(
            left: 22,
            bottom: 22,
            child: GestureDetector(
              onTap: onGalleryTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: WireframeColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: WireframeColors.border, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  'Gallery',
                  style: TextStyle(
                    color: WireframeColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),

          // 5. "Retake" Button (Visible only when photo is previewed)
          if (hasImage)
            Positioned(
              right: 22,
              bottom: 22,
              child: GestureDetector(
                onTap: onRetakeTap ?? onCaptureTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: WireframeColors.primaryDark,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, size: 16, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Retake',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Custom painter for the center dashed rounded rectangle.
class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;

  _DashedRRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final dashedPath = _createDashedPath(path, dashWidth: 6.0, dashSpace: 4.0);
    canvas.drawPath(dashedPath, paint);
  }

  Path _createDashedPath(Path source, {required double dashWidth, required double dashSpace}) {
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final length = distance + dashWidth > metric.length ? metric.length - distance : dashWidth;
        dest.addPath(metric.extractPath(distance, distance + length), Offset.zero);
        distance += dashWidth + dashSpace;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
