import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_settings_model.dart';

/// Contract for local settings persistence.
abstract class SettingsLocalDataSource {
  Future<UserSettingsModel> getSettings();
  Future<void> saveSettings(UserSettingsModel model);
}

/// SharedPreferences implementation of [SettingsLocalDataSource].
///
/// Includes in-memory fallback if platform channel binding is unavailable in unit tests.
class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  static const String keyNotificationSoundsEnabled =
      'settings_notification_sounds_enabled';
  static const String keySoundType = 'settings_sound_type';

  // In-memory fallback
  static bool? _fallbackNotificationSoundsEnabled;
  static String? _fallbackSoundType;

  final SharedPreferences? prefs;

  SettingsLocalDataSourceImpl({this.prefs});

  Future<SharedPreferences?> _getPrefs() async {
    if (prefs != null) return prefs;
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UserSettingsModel> getSettings() async {
    final sp = await _getPrefs();
    if (sp != null) {
      final soundsEnabled = sp.getBool(keyNotificationSoundsEnabled) ?? true;
      final soundType = sp.getString(keySoundType) ?? 'cat';
      return UserSettingsModel(
        notificationSoundsEnabled: soundsEnabled,
        soundType: soundType,
      );
    }

    return UserSettingsModel(
      notificationSoundsEnabled: _fallbackNotificationSoundsEnabled ?? true,
      soundType: _fallbackSoundType ?? 'cat',
    );
  }

  @override
  Future<void> saveSettings(UserSettingsModel model) async {
    _fallbackNotificationSoundsEnabled = model.notificationSoundsEnabled;
    _fallbackSoundType = model.soundType;

    final sp = await _getPrefs();
    if (sp != null) {
      await sp.setBool(keyNotificationSoundsEnabled, model.notificationSoundsEnabled);
      await sp.setString(keySoundType, model.soundType);
    }
  }
}
