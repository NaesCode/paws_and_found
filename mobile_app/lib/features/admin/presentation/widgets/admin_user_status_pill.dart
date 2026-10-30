import 'package:flutter/material.dart';
import '../../../../core/theme/wireframe_colors.dart';

/// User account status pill badge matching SDD Screen 09.
///
/// Styles:
/// - 'Active': White background, subtle border, dark slate text.
/// - 'Warning': Amber-100 background, amber border, amber-700 text.
/// - 'Suspension' / 'Suspended': Dark slate solid background, white text.
class AdminUserStatusPill extends StatelessWidget {
  final String status;
  final VoidCallback? onTap;

  const AdminUserStatusPill({
    super.key,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    final isSuspended = s.contains('suspend');
    final isWarning = s == 'warning';

    Color bgColor;
    Color textColor;
    Border? border;

    if (isSuspended) {
      bgColor = WireframeColors.primaryDark;
      textColor = Colors.white;
      border = null;
    } else if (isWarning) {
      bgColor = const Color(0xFFFEF3C7);
      textColor = const Color(0xFFB45309);
      border = Border.all(color: const Color(0xFFF59E0B), width: 1.2);
    } else {
      // Active / default
      bgColor = WireframeColors.surface;
      textColor = WireframeColors.primaryDark;
      border = Border.all(color: WireframeColors.border, width: 1.2);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9.0, vertical: 3.5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14.0),
          border: border,
        ),
        child: Text(
          status,
          maxLines: 1,
          softWrap: false,
          style: TextStyle(
            color: textColor,
            fontSize: 11.0,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
