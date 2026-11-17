import '../entities/user_settings.dart';

/// Contract for loading and saving user application settings.
///
/// Clean Architecture: Domain Layer (Repository interface).
abstract class SettingsRepository {
  /// Loads current user settings.
  Future<UserSettings> getSettings();

  /// Persists updated user settings.
  Future<void> saveSettings(UserSettings settings);
}
