import 'package:flutter/material.dart';

/// Renders the AI / Admin Content Moderation Status pill for Post Management.
///
/// Statuses:
/// - `flagged`: Amber badge indicating post was flagged by SSDLite320 / AI moderation.
/// - `rejected`: Red badge indicating post was rejected by admin.
/// - `approved`: Green badge indicating post was verified and approved.
class AdminModerationPill extends StatelessWidget {
  final String status;
  final bool showLabel;

  const AdminModerationPill({
    super.key,
    required this.status,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase().trim();

    Color bgColor;
    Color textColor;
    Color borderColor;
    String label;
    IconData icon;

    switch (s) {
      case 'flagged':
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFB45309);
        borderColor = const Color(0xFFFCD34D);
        label = 'AI Flagged';
        icon = Icons.flag_rounded;
        break;
      case 'rejected':
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFB91C1C);
        borderColor = const Color(0xFFFCA5A5);
        label = 'Rejected';
        icon = Icons.cancel_outlined;
        break;
      case 'approved':
      default:
        bgColor = const Color(0xFFECFDF5);
        textColor = const Color(0xFF047857);
        borderColor = const Color(0xFFA7F3D0);
        label = 'Approved';
        icon = Icons.check_circle_outline_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11.0, color: textColor),
          if (showLabel) ...[
            const SizedBox(width: 3.5),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.0,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

