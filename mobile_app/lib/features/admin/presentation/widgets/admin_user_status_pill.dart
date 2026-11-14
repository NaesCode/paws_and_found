import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// User account status pill badge matching SDD Screen 09 with veterinary styling.
///
/// Styles:
/// - 'Active': Clean white background, subtle border, Forest Teal text.
/// - 'Warning': Amber-100 background, amber border, amber-700 text.
/// - 'Suspension' / 'Suspended': Forest Teal solid background, white text.
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
      bgColor = AppColors.primary;
      textColor = Colors.white;
      border = null;
    } else if (isWarning) {
      bgColor = const Color(0xFFFEF3C7);
      textColor = const Color(0xFFB45309);
      border = Border.all(color: const Color(0xFFF59E0B), width: 1.2);
    } else {
      // Active / default
      bgColor = AppColors.surface;
      textColor = AppColors.primary;
      border = Border.all(color: AppColors.border, width: 1.2);
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
