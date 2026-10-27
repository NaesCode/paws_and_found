import 'package:flutter/material.dart';

/// An atomic button that triggers moving or recentering the map camera
/// to the user's current GPS location.
///
/// Adheres strictly to Atomic Design: dumb, stateless UI element relying purely
/// on passed properties and callbacks.
class CurrentLocationButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isLoading;
  final double size;
  final String tooltip;

  const CurrentLocationButton({
    super.key,
    required this.onTap,
    this.isLoading = false,
    this.size = 44.0,
    this.tooltip = 'My Current Location',
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3.5,
      shadowColor: Colors.black.withValues(alpha: 0.28),
      borderRadius: BorderRadius.circular(12),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isLoading ? null : onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 1.0,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              isLoading
                  ? Icons.location_searching_rounded
                  : Icons.my_location_rounded,
              color: isLoading
                  ? const Color(0xFF6B7280)
                  : const Color(0xFF1F2937),
              size: size * 0.52,
            ),
          ),
        ),
      ),
    );
  }
}
