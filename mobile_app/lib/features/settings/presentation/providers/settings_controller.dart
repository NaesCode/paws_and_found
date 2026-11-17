import 'package:flutter/foundation.dart';
import '../../domain/entities/user_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../../../shared/molecules/sound_type_selector_tile.dart';

/// State management controller for application settings.
///
/// Clean Architecture: Presentation Layer (Provider / State Management).
class SettingsController extends ChangeNotifier {
  final SettingsRepository _repository;

  UserSettings _settings = const UserSettings();
  bool _isLoading = true;

  SettingsController({SettingsRepository? repository})
      : _repository = repository ?? SettingsRepositoryImpl();

  UserSettings get settings => _settings;
  bool get isLoading => _isLoading;
  bool get notificationSoundsEnabled => _settings.notificationSoundsEnabled;
  NotificationSoundType get soundType =>
      NotificationSoundType.fromId(_settings.soundType);

  /// Loads persisted settings on initialization.
  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      _settings = await _repository.getSettings();
    } catch (_) {
      // Retain default settings on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates and persists the notification sounds toggle.
  Future<void> setNotificationSounds(bool enabled) async {
    _settings = _settings.copyWith(notificationSoundsEnabled: enabled);
    notifyListeners();
    await _repository.saveSettings(_settings);
  }

  /// Updates and persists the selected sound type.
  Future<void> setSoundType(NotificationSoundType type) async {
    _settings = _settings.copyWith(soundType: type.id);
    notifyListeners();
    await _repository.saveSettings(_settings);
  }
}
