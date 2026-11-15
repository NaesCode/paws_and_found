/// Domain entity representing user configuration and preferences.
///
/// Clean Architecture: Domain Layer (pure business entity).
class UserSettings {
  final bool notificationSoundsEnabled;
  final String soundType; // 'cat', 'dog', 'bird'

  const UserSettings({
    this.notificationSoundsEnabled = true,
    this.soundType = 'cat',
  });

  UserSettings copyWith({
    bool? notificationSoundsEnabled,
    String? soundType,
  }) {
    return UserSettings(
      notificationSoundsEnabled:
          notificationSoundsEnabled ?? this.notificationSoundsEnabled,
      soundType: soundType ?? this.soundType,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSettings &&
          runtimeType == other.runtimeType &&
          notificationSoundsEnabled == other.notificationSoundsEnabled &&
          soundType == other.soundType;

  @override
  int get hashCode =>
      notificationSoundsEnabled.hashCode ^ soundType.hashCode;
}
