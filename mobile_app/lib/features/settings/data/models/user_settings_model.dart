import '../../domain/entities/user_settings.dart';

/// Data model for UserSettings serialization.
///
/// Clean Architecture: Data Layer (Model).
class UserSettingsModel extends UserSettings {
  const UserSettingsModel({
    super.notificationSoundsEnabled = true,
    super.soundType = 'cat',
  });

  factory UserSettingsModel.fromEntity(UserSettings entity) {
    return UserSettingsModel(
      notificationSoundsEnabled: entity.notificationSoundsEnabled,
      soundType: entity.soundType,
    );
  }

  factory UserSettingsModel.fromJson(Map<String, dynamic> json) {
    return UserSettingsModel(
      notificationSoundsEnabled: json['notification_sounds_enabled'] as bool? ?? true,
      soundType: (json['sound_type'] as String?) ?? 'cat',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notification_sounds_enabled': notificationSoundsEnabled,
      'sound_type': soundType,
    };
  }
}
