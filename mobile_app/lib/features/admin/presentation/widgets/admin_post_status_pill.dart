import 'package:flutter/material.dart';
import '../../../../core/theme/wireframe_colors.dart';

/// Animal post status pill badge matching SDD Screen 10.
///
/// Styles:
/// - 'Missing': Dark slate solid background, bold white text.
/// - 'Stray': Medium slate solid background, bold white text.
/// - 'Found': White background, dark slate border, dark slate text.
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
      bgColor = WireframeColors.badgeMissingBg;
      textColor = WireframeColors.badgeMissingText;
      border = null;
    } else if (isStray) {
      bgColor = WireframeColors.badgeStrayBg;
      textColor = WireframeColors.badgeStrayText;
      border = null;
    } else if (isFound) {
      bgColor = WireframeColors.badgeFoundBg;
      textColor = WireframeColors.badgeFoundText;
      border = Border.all(color: WireframeColors.badgeFoundBorder, width: 1.2);
    } else {
      bgColor = WireframeColors.secondarySlate;
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
        status.substring(0, 1).toUpperCase() + status.substring(1).toLowerCase(),
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

