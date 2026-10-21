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
  final Widget? cameraPreview;
  final bool isCameraInitialized;
  final bool isTakingPicture;
  final VoidCallback? onCaptureTap;
  final VoidCallback? onGalleryTap;
  final VoidCallback? onRetakeTap;

  const CameraViewfinderPlaceholder({
    super.key,
    this.height = 270.0,
    this.imageBytes,
    this.cameraPreview,
    this.isCameraInitialized = false,
    this.isTakingPicture = false,
    this.onCaptureTap,
    this.onGalleryTap,
    this.onRetakeTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasImage = imageBytes != null && imageBytes!.isNotEmpty;
    final bool showLiveCamera = !hasImage && isCameraInitialized && cameraPreview != null;

    return Container(
      width: double.infinity,
      height: height,
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Live Camera Stream (when active)
          if (showLiveCamera)
            ClipRect(
              child: OverflowBox(
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: cameraPreview!,
                ),
              ),
            ),

          // 2. Captured Image Preview (when photo is taken or picked)
          if (hasImage)
            Image.memory(
              imageBytes!,
              fit: BoxFit.cover,
            ),

          // 3. Fallback wireframe placeholder (when camera not initialized / tests / emulators)
          if (!hasImage && !showLiveCamera)
            Container(
              color: WireframeColors.surfaceSecondary,
              child: Center(
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
            ),

          // 4. Corner Framing Brackets (visual framing overlay)
          Positioned.fill(
            child: IgnorePointer(
              child: CameraViewfinderBrackets(
                bracketLength: 28.0,
                strokeWidth: 2.5,
                color: showLiveCamera ? Colors.white.withValues(alpha: 0.85) : WireframeColors.primaryDark,
                padding: const EdgeInsets.all(22.0),
              ),
            ),
          ),

          // 5. Live Camera Shutter Button (Visible during live camera feed)
          if (showLiveCamera)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: isTakingPicture ? null : onCaptureTap,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3.5),
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: isTakingPicture
                          ? const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: WireframeColors.primaryDark,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt_rounded,
                              color: WireframeColors.primaryDark,
                              size: 24,
                            ),
                    ),
                  ),
                ),
              ),
            ),

          // 6. "Gallery" Button in Bottom-Left
          Positioned(
            left: 22,
            bottom: 22,
            child: GestureDetector(
              onTap: onGalleryTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: showLiveCamera ? Colors.black.withValues(alpha: 0.55) : WireframeColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: showLiveCamera ? Colors.white.withValues(alpha: 0.4) : WireframeColors.border,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 16,
                      color: showLiveCamera ? Colors.white : WireframeColors.textPrimary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Gallery',
                      style: TextStyle(
                        color: showLiveCamera ? Colors.white : WireframeColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 7. "Retake" Button (Visible only when photo is previewed)
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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
