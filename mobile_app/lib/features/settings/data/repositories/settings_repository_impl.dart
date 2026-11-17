import '../../domain/entities/user_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_datasource.dart';
import '../models/user_settings_model.dart';

/// Implementation of [SettingsRepository] following Clean Architecture.
class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource _dataSource;

  SettingsRepositoryImpl({SettingsLocalDataSource? dataSource})
      : _dataSource = dataSource ?? SettingsLocalDataSourceImpl();

  @override
  Future<UserSettings> getSettings() async {
    return await _dataSource.getSettings();
  }

  @override
  Future<void> saveSettings(UserSettings settings) async {
    final model = UserSettingsModel.fromEntity(settings);
    await _dataSource.saveSettings(model);
  }
}
