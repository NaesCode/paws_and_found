import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/molecules/settings_tile.dart';

/// Presentation card grouping legal agreements and policy document links.
///
/// Adheres strictly to Atomic Design and Clean Architecture.
class SettingsLegalCard extends StatelessWidget {
  final VoidCallback onTermsPressed;
  final VoidCallback onPrivacyPressed;

  const SettingsLegalCard({
    super.key,
    required this.onTermsPressed,
    required this.onPrivacyPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SettingsTile(
            icon: Icons.article_outlined,
            iconColor: AppColors.primary,
            title: 'Terms of Service',
            subtitle: 'Read community guidelines and platform rules',
            onTap: onTermsPressed,
          ),
          const Divider(height: 1, indent: 68, color: AppColors.borderLight),
          SettingsTile(
            icon: Icons.privacy_tip_outlined,
            iconColor: AppColors.primary,
            title: 'Privacy Policy',
            subtitle: 'Learn how your data, sightings, and GPS are protected',
            onTap: onPrivacyPressed,
          ),
        ],
      ),
    );
  }
}
