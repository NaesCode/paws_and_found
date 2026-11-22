import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';

/// Full-page restriction widget displayed when a suspended user navigates to the Feeds page.
///
/// SDD / Account Restrictions:
/// - Informs user of account suspension resulting from community guideline infractions.
/// - Blocks viewing or contributing to community animal feeds and personal reports.
/// - Provides a direct "Contact Admin" action dialog with copyable support email.
/// - Provides a "Check Status" refresh action to detect when account status is restored.
class FeedSuspendedView extends StatelessWidget {
  final VoidCallback? onRefreshStatus;
  final String adminEmail;

  const FeedSuspendedView({
    super.key,
    this.onRefreshStatus,
    this.adminEmail = 'support@pawsandfound.org',
  });

  void _showContactAdminDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.support_agent_rounded, color: AppColors.primary, size: 26),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Contact Administration',
                style: TextStyle(
                  fontFamily: 'Nunito Sans',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkCharcoal,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'If you believe your account was suspended in error or wish to submit an appeal, please email our moderation team:',
              style: TextStyle(
                fontFamily: 'Ek Mukta',
                fontSize: 13.5,
                color: AppColors.darkSlate,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mail_outline_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SelectableText(
                      adminEmail,
                      style: const TextStyle(
                        fontFamily: 'Nunito Sans',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.darkCharcoal,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('copy_admin_email_button'),
                    icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primary),
                    tooltip: 'Copy Email',
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: adminEmail));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Admin email copied to clipboard!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Note: Please include your registered username and details regarding your appeal.',
              style: TextStyle(
                fontFamily: 'Ek Mukta',
                fontSize: 12,
                color: AppColors.text3,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text(
              'Close',
              style: TextStyle(
                fontFamily: 'Nunito Sans',
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          key: const Key('feed_suspended_view'),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Shield & Alert Badge Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red.shade200, width: 2),
              ),
              child: const Icon(
                Icons.gpp_bad_rounded,
                size: 42,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              'Account Suspended',
              style: TextStyle(
                fontFamily: 'Nunito Sans',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.darkCharcoal,
              ),
            ),
            const SizedBox(height: 10),

            // Description
            const Text(
              'Access to Community Animal Reports and discussions has been restricted due to violations of our community safety guidelines.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Ek Mukta',
                fontSize: 14,
                color: AppColors.text3,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),

            // Warning note card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background2.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 20, color: AppColors.error),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Repeated infractions or prohibited language violations have restricted your posting and feed viewing privileges.',
                      style: TextStyle(
                        fontFamily: 'Ek Mukta',
                        fontSize: 12.5,
                        color: AppColors.darkSlate,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Contact Admin Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                key: const Key('contact_admin_button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.contrast2,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.support_agent_rounded, size: 20),
                label: const Text(
                  'Contact Admin',
                  style: TextStyle(
                    fontFamily: 'Nunito Sans',
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                onPressed: () => _showContactAdminDialog(context),
              ),
            ),
            const SizedBox(height: 12),

            // Refresh / Check Status Button
            if (onRefreshStatus != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const Key('refresh_status_button'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.darkCharcoal,
                    side: BorderSide(color: Colors.grey.shade400),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text(
                    'Check Account Status',
                    style: TextStyle(
                      fontFamily: 'Nunito Sans',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  onPressed: onRefreshStatus,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
