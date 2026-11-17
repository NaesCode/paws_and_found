import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/molecules/settings_switch_tile.dart';
import '../../../../shared/molecules/sound_type_selector_tile.dart';

/// Presentation card grouping sound alert preferences.
///
/// Adheres strictly to Atomic Design and Clean Architecture.
class SettingsSoundCard extends StatelessWidget {
  final bool notificationSoundsEnabled;
  final NotificationSoundType soundType;
  final ValueChanged<bool> onSoundsToggled;
  final ValueChanged<NotificationSoundType> onSoundTypeChanged;

  const SettingsSoundCard({
    super.key,
    required this.notificationSoundsEnabled,
    required this.soundType,
    required this.onSoundsToggled,
    required this.onSoundTypeChanged,
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
          SettingsSwitchTile(
            icon: notificationSoundsEnabled
                ? Icons.volume_up_rounded
                : Icons.volume_off_rounded,
            iconColor: notificationSoundsEnabled
                ? AppColors.primary
                : AppColors.textMuted,
            title: 'Notification Sounds',
            subtitle: notificationSoundsEnabled
                ? 'Play audible alerts for new sightings & messages'
                : 'Audible alerts are muted',
            value: notificationSoundsEnabled,
            onChanged: onSoundsToggled,
          ),
          const Divider(height: 1, indent: 68, color: AppColors.borderLight),
          SoundTypeSelectorTile(
            selectedType: soundType,
            onTypeChanged: onSoundTypeChanged,
            enabled: notificationSoundsEnabled,
          ),
        ],
      ),
    );
  }
}
