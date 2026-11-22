import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_assets.dart';
import '../../features/notifications/domain/entities/app_notification.dart';
import '../../features/settings/data/datasources/settings_local_datasource.dart';

/// Singleton service responsible for playing species-inspired notification chimes.
///
/// Adheres strictly to Clean Architecture (lib/core/services/).
class AudioAlertService {
  static final AudioAlertService instance = AudioAlertService._internal();

  final AudioPlayer _player;
  final SettingsLocalDataSource _settingsDataSource;
  final SupabaseClient? _supabase;

  static SupabaseClient? _getSafeSupabaseClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  AudioAlertService({
    AudioPlayer? player,
    SettingsLocalDataSource? settingsDataSource,
    SupabaseClient? supabase,
  })  : _player = player ?? AudioPlayer(),
        _settingsDataSource = settingsDataSource ?? SettingsLocalDataSourceImpl(),
        _supabase = supabase ?? _getSafeSupabaseClient();

  AudioAlertService._internal()
      : _player = AudioPlayer(),
        _settingsDataSource = SettingsLocalDataSourceImpl(),
        _supabase = _getSafeSupabaseClient();

  /// Resolves the asset path for a given sound type ID.
  static String resolveAssetForType(String soundId) {
    switch (soundId.toLowerCase()) {
      case 'dog':
        return AppAssets.soundDog;
      case 'puppy':
        return AppAssets.soundPuppy;
      case 'bird':
        return AppAssets.soundBird;
      case 'macaw':
        return AppAssets.soundMacaw;
      case 'kitten':
        return AppAssets.soundKitten;
      case 'system':
        return AppAssets.soundSystem;
      case 'cat':
      default:
        return AppAssets.soundCat;
    }
  }

  /// Converts a full asset path like 'assets/audio/cat_default1.wav'
  /// to the relative path expected by audioplayers AssetSource ('audio/cat_default1.wav').
  static String _cleanAssetPath(String fullPath) {
    if (fullPath.startsWith('assets/')) {
      return fullPath.substring('assets/'.length);
    }
    return fullPath;
  }

  /// Plays an instant audio preview of a sound asset or sound type ID.
  Future<void> playPreview(String soundAssetOrId) async {
    try {
      final rawPath = soundAssetOrId.contains('/')
          ? soundAssetOrId
          : resolveAssetForType(soundAssetOrId);

      final cleanPath = _cleanAssetPath(rawPath);

      // Stop any currently playing chime before starting new one
      await _player.stop();
      await _player.play(AssetSource(cleanPath));
    } catch (e) {
      debugPrint('[AudioAlertService] Could not play preview: $e');
    }
  }

  /// Plays the user's active notification sound chime if enabled in settings.
  Future<void> playNotificationAlert({String? overrideSoundType}) async {
    try {
      final settings = await _settingsDataSource.getSettings();
      if (!settings.notificationSoundsEnabled) {
        return; // Muted by user setting
      }

      final soundId = overrideSoundType ?? settings.soundType;
      await playPreview(soundId);
    } catch (e) {
      debugPrint('[AudioAlertService] Could not play notification alert: $e');
    }
  }

  /// Plays the species chime configured for the pet referenced in [notification].
  /// Falls back to the global notification sound setting if no pet or custom sound is found.
  Future<void> playNotificationAlertForNotification(AppNotification notification) async {
    try {
      final settings = await _settingsDataSource.getSettings();
      if (!settings.notificationSoundsEnabled) {
        return; // Muted by user setting
      }

      String? petSound;

      if (_supabase != null) {
        // 1. Try resolving via relatedMatchId if available
        final matchId = notification.relatedMatchId;
        if (matchId != null && matchId.isNotEmpty) {
          try {
            final matchData = await _supabase
                .from('matches')
                .select('pets(alert_sound)')
                .eq('id', matchId)
                .maybeSingle();

            if (matchData != null && matchData['pets'] != null) {
              petSound = matchData['pets']['alert_sound'] as String?;
            }
          } catch (_) {}
        }

        // 2. Try resolving via relatedReportId if petSound is still null
        final reportId = notification.relatedReportId;
        if (petSound == null && reportId != null && reportId.isNotEmpty) {
          try {
            final reportData = await _supabase
                .from('reports')
                .select('pet_id, pets(alert_sound)')
                .eq('id', reportId)
                .maybeSingle();

            if (reportData != null && reportData['pets'] != null) {
              petSound = reportData['pets']['alert_sound'] as String?;
            }
          } catch (_) {}
        }

        // 3. For pet recovery / claim updates, resolve pet's sound via pet_claims
        if (petSound == null &&
            (notification.type == 'claim_request' || notification.type == 'claim_update') &&
            reportId != null &&
            reportId.isNotEmpty) {
          try {
            final currentUserId = _supabase.auth.currentUser?.id;
            if (currentUserId != null) {
              // Resolve the claim associated with this report
              final claimData = await _supabase
                  .from('pet_claims')
                  .select('claimer_id, finder_id')
                  .eq('report_id', reportId)
                  .or('finder_id.eq.$currentUserId,claimer_id.eq.$currentUserId')
                  .maybeSingle();

              if (claimData != null) {
                final claimerId = claimData['claimer_id']?.toString() ?? currentUserId;
                final petData = await _supabase
                    .from('pets')
                    .select('alert_sound')
                    .eq('owner_id', claimerId)
                    .not('alert_sound', 'is', null)
                    .limit(1)
                    .maybeSingle();

                if (petData != null) {
                  petSound = petData['alert_sound'] as String?;
                }
              }
            }
          } catch (_) {}
        }
      }

      final soundId = petSound ?? settings.soundType;
      await playPreview(soundId);
    } catch (e) {
      debugPrint('[AudioAlertService] Could not resolve pet sound, falling back: $e');
      await playNotificationAlert();
    }
  }

  void dispose() {
    _player.dispose();
  }
}
