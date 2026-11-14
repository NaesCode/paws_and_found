import 'package:flutter/material.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';

/// A circular map marker pin atom used on the interactive map canvas and location pickers.
///
/// Adheres to Atomic Design: dumb, stateless UI element relying purely on
/// passed properties.
///
/// Visual styles (Veterinary / Clinical Theme):
/// - 'M' / Missing: Deep Maroon alert filled circle with white text.
/// - 'S' / Stray: Warm Accent Orange filled circle with white text.
/// - 'F' / Found: Clean white circle with Forest Teal border and text.
class MapPinBadge extends StatelessWidget {
  final String label;
  final String status;
  final bool isSelected;
  final VoidCallback? onTap;
  final double size;

  const MapPinBadge({
    super.key,
    required this.label,
    required this.status,
    this.isSelected = false,
    this.onTap,
    this.size = 38.0,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = status.toLowerCase();
    final bool isMissing = normalizedStatus == 'missing' || label == 'M';
    final bool isStray = normalizedStatus == 'stray' || label == 'S';
    final bool isFound = normalizedStatus == 'found' || label == 'F';

    Color bgColor;
    Color textColor;
    Border? border;

    if (isMissing) {
      bgColor = AppColors.statusMissing;
      textColor = Colors.white;
      border = null;
    } else if (isStray) {
      bgColor = AppColors.statusStray;
      textColor = Colors.white;
      border = null;
    } else if (isFound) {
      bgColor = AppColors.surface;
      textColor = AppColors.primary;
      border = Border.all(color: AppColors.primary, width: 2.2);
    } else {
      bgColor = AppColors.textSecondary;
      textColor = Colors.white;
      border = null;
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: isSelected ? size + 10 : size,
        height: isSelected ? size + 10 : size,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: border,
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 10,
                spreadRadius: 3,
                offset: const Offset(0, 2),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: textColor,
            fontSize: isSelected ? 15.0 : 13.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
