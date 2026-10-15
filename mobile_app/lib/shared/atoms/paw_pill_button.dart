import 'package:flutter/material.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';
import 'package:paws_and_found/core/theme/app_typography.dart';

/// A reusable stadium-shaped pill button atom.
///
/// Designed for compact buttons such as "+ Add pet" or "Report Missing!".
/// Provides a comfortable touch target while preserving a small visual footprint.
class PawPillButton extends StatelessWidget {
  final String? text;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final EdgeInsetsGeometry padding;
  final TextStyle? textStyle;
  final double elevation;
  final bool isLoading;

  const PawPillButton({
    super.key,
    this.text,
    this.leadingIcon,
    this.trailingIcon,
    this.onPressed,
    this.backgroundColor = AppColors.primary,
    this.foregroundColor = AppColors.text1,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    this.textStyle,
    this.elevation = 0,
    this.isLoading = false,
  });

  /// Factory constructor for a primary (Teal) pill button (e.g., "+ Add Pet")
  factory PawPillButton.primary({
    Key? key,
    String? text,
    Widget? leadingIcon,
    Widget? trailingIcon,
    VoidCallback? onPressed,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    bool isLoading = false,
  }) {
    return PawPillButton(
      key: key,
      text: text,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      onPressed: onPressed,
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.text1,
      padding: padding,
      isLoading: isLoading,
    );
  }

  /// Factory constructor for a contrast2 (Maroon) pill button (e.g., "Report Missing!")
  factory PawPillButton.danger({
    Key? key,
    required String text,
    Widget? leadingIcon,
    Widget? trailingIcon,
    VoidCallback? onPressed,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    bool isLoading = false,
  }) {
    return PawPillButton(
      key: key,
      text: text,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      onPressed: onPressed,
      backgroundColor: AppColors.contrast2,
      foregroundColor: AppColors.text1,
      padding: padding,
      isLoading: isLoading,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Touch target is minimum 44px height for accessibility
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 32, minWidth: 32),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(999),
              boxShadow: elevation > 0
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: elevation * 2,
                        offset: Offset(0, elevation),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (isLoading) ...[
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                    ),
                  ),
                ] else ...[
                  if (leadingIcon != null) ...[
                    leadingIcon!,
                    if (text != null) const SizedBox(width: 4),
                  ],
                  if (text != null)
                    Text(
                      text!,
                      style: (textStyle ?? AppTypography.pillText).copyWith(
                        color: foregroundColor,
                      ),
                    ),
                  if (trailingIcon != null) ...[
                    if (text != null) const SizedBox(width: 4),
                    trailingIcon!,
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

