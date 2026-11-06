import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Animal post status pill badge matching SDD Screen 10 with clinical branding.
///
/// Styles:
/// - 'Missing': Maroon alert background, bold white text.
/// - 'Stray': Warm orange background, bold white text.
/// - 'Found': Clean white background, Forest Teal border & text.
class AdminPostStatusPill extends StatelessWidget {
  final String status;

  const AdminPostStatusPill({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final lower = status.toLowerCase();
    final bool isMissing = lower == 'missing';
    final bool isStray = lower == 'stray';
    final bool isFound = lower == 'found';

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
      border = Border.all(color: AppColors.primary, width: 1.2);
    } else {
      bgColor = AppColors.textSecondary;
      textColor = Colors.white;
      border = null;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6.0),
        border: border,
      ),
      child: Text(
        status.isEmpty
            ? ''
            : status.substring(0, 1).toUpperCase() + status.substring(1).toLowerCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
