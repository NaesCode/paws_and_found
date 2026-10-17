import 'package:flutter/material.dart';
import '../../core/theme/wireframe_colors.dart';

/// A status badge atom showing "MISSING", "STRAY", or "FOUND" in wireframe styling.
///
/// Adheres to Atomic Design: dumb, stateless UI element relying purely on
/// passed properties.
class WireframeStatusBadge extends StatelessWidget {
  final String status;
  final String? label;
  final EdgeInsetsGeometry padding;

  const WireframeStatusBadge({
    super.key,
    required this.status,
    this.label,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final displayText = (label ?? status).toUpperCase();

    Color bgColor;
    Color textColor;
    Border? border;

    switch (normalized) {
      case 'missing':
        bgColor = WireframeColors.badgeMissingBg;
        textColor = WireframeColors.badgeMissingText;
        border = null;
        break;
      case 'stray':
        bgColor = WireframeColors.badgeStrayBg;
        textColor = WireframeColors.badgeStrayText;
        border = null;
        break;
      case 'found':
        bgColor = WireframeColors.badgeFoundBg;
        textColor = WireframeColors.badgeFoundText;
        border = Border.all(color: WireframeColors.badgeFoundBorder, width: 1.5);
        break;
      default:
        bgColor = WireframeColors.secondarySlate;
        textColor = Colors.white;
        border = null;
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: border,
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: textColor,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
