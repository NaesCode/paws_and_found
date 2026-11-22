import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// A reusable dialog molecule alerting users when their content violates community guidelines.
///
/// Adheres strictly to Atomic Design (lib/shared/molecules/) and is a dumb component
/// that relies strictly on passed parameters and callbacks.
class CommunityWarningDialog extends StatelessWidget {
  /// The prohibited term detected in the user's input.
  final String detectedWord;

  /// Total number of cumulative violations/attempts recorded for the user.
  final int violationCount;

  /// Whether this violation has triggered an immediate account suspension.
  final bool isSuspended;

  /// Optional custom callback invoked when the user dismisses the dialog.
  final VoidCallback? onDismiss;

  const CommunityWarningDialog({
    super.key,
    required this.detectedWord,
    required this.violationCount,
    this.isSuspended = false,
    this.onDismiss,
  });

  /// Static helper to display the [CommunityWarningDialog] cleanly.
  static Future<void> show({
    required BuildContext context,
    required String detectedWord,
    required int violationCount,
    bool isSuspended = false,
    VoidCallback? onDismiss,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CommunityWarningDialog(
        detectedWord: detectedWord,
        violationCount: violationCount,
        isSuspended: isSuspended,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 6,
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 22.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header with Warning Icon & Title
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange.shade700,
                  size: 28,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Community Warning',
                    style: TextStyle(
                      fontFamily: 'Nunito Sans',
                      color: AppColors.darkCharcoal,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 2. Primary Explanation
            const Text(
              'Your comment was not posted because it contains prohibited language in our community guidelines.',
              style: TextStyle(
                fontFamily: 'Ek Mukta',
                color: AppColors.darkCharcoal,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),

            // 3. Highlighted Detected Word Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE), // Soft red badge background
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFCDD2)),
              ),
              child: Text(
                'Detected: "$detectedWord"',
                style: const TextStyle(
                  fontFamily: 'Nunito Sans',
                  color: Color(0xFFD32F2F), // Bold warning red
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 4. Escalation Warning / Suspension Notice
            Text(
              isSuspended
                  ? 'Warning: Your account has been suspended due to repeated violations ($violationCount violations recorded).'
                  : 'Warning: Continued use of prohibited language will result in account suspension ($violationCount violations recorded).',
              style: const TextStyle(
                fontFamily: 'Ek Mukta',
                color: AppColors.darkCharcoal,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),

            // 5. 'Understood' Dismiss Button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const Key('community_warning_understood_button'),
                onPressed: () {
                  Navigator.of(context).pop();
                  if (onDismiss != null) {
                    onDismiss!();
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  textStyle: const TextStyle(
                    fontFamily: 'Nunito Sans',
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                  ),
                ),
                child: const Text('Understood'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
