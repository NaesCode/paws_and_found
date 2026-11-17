import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/atoms/settings_section_header.dart';
import '../../../../shared/organisms/legal_document_dialog.dart';
import '../../../../shared/templates/settings_screen_template.dart';
import '../../domain/repositories/settings_repository.dart';
import '../providers/settings_controller.dart';
import '../widgets/settings_legal_card.dart';
import '../widgets/settings_sound_card.dart';

/// The Settings & Preferences screen for Paws and Found.
///
/// Accessible from the Profile page overflow tray.
/// Allows managing notification sounds, sound types, and viewing legal documents.
/// Adheres strictly to Atomic Design and Clean Architecture.
class SettingsPage extends StatefulWidget {
  final SettingsRepository? repository;
  final SettingsController? controller;

  const SettingsPage({
    super.key,
    this.repository,
    this.controller,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final SettingsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ??
        SettingsController(repository: widget.repository);
    _controller.addListener(_onControllerUpdate);
    _controller.loadSettings();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScreenTemplate(
      title: 'Settings',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Audio / Notification Sounds Section
          const SettingsSectionHeader(title: 'Alert Preferences'),
          SettingsSoundCard(
            notificationSoundsEnabled: _controller.notificationSoundsEnabled,
            soundType: _controller.soundType,
            onSoundsToggled: (enabled) {
              _controller.setNotificationSounds(enabled);
            },
            onSoundTypeChanged: (type) {
              _controller.setSoundType(type);
            },
          ),

          const SizedBox(height: 12),

          // 2. Legal & Policies Section
          const SettingsSectionHeader(title: 'Legal & Policies'),
          SettingsLegalCard(
            onTermsPressed: () {
              LegalDocumentDialog.showTermsOfService(context);
            },
            onPrivacyPressed: () {
              LegalDocumentDialog.showPrivacyPolicy(context);
            },
          ),

          const SizedBox(height: 28),

          // 3. Application Version & Community Badge Footer
          Center(
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Paws and Found · v1.0.0',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Community Lost & Found Animal Recovery',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
