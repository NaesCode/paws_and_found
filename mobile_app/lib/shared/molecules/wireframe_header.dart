import 'package:flutter/material.dart';
import '../../core/theme/wireframe_typography.dart';

/// A universal top screen header molecule for wireframe screens.
///
/// Provides:
/// - Screen title in wireframe bold typography
/// - Optional leading button (e.g. Back button or Menu)
/// - Optional trailing action buttons (e.g. Settings, Search, Re-center, Filter)
///
/// Adheres to Atomic Design: dumb, stateless UI element relying purely on
/// passed properties.
class WireframeHeader extends StatelessWidget {
  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final EdgeInsetsGeometry padding;

  const WireframeHeader({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.padding = const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              title,
              style: WireframeTypography.screenTitle,
            ),
          ),
          if (actions != null && actions!.isNotEmpty) ...[
            const SizedBox(width: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: actions!,
            ),
          ],
        ],
      ),
    );
  }
}
