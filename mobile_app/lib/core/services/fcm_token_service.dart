import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Singleton service responsible for registering and syncing FCM tokens
/// with Supabase for remote cloud push notifications.
///
/// Adheres strictly to Clean Architecture (lib/core/services/).
class FcmTokenService {
  static final FcmTokenService instance = FcmTokenService._internal();

  final SupabaseClient _supabase;
  bool _isInitialized = false;
  StreamSubscription<String>? _tokenRefreshSub;

  FcmTokenService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  FcmTokenService._internal() : _supabase = Supabase.instance.client;

  /// Initializes Firebase and subscribes to token rotations.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Ensure Firebase Core is initialized
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      // Listen to automated Google FCM token rotations
      _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen(
        (newToken) => _upsertToken(newToken),
        onError: (e) {
          debugPrint('[FcmTokenService] Token refresh stream error: $e');
        },
      );

      _isInitialized = true;
    } catch (e) {
      debugPrint('[FcmTokenService] Initialization error (Firebase setup): $e');
    }
  }

  /// Syncs the current device's FCM token with Supabase for the active user.
  Future<void> syncToken() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final user = _supabase.auth.currentUser;
      if (user == null) {
        return; // No authenticated session to bind token to
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await _upsertToken(token);
      }
    } catch (e) {
      debugPrint('[FcmTokenService] Failed to retrieve/sync FCM token: $e');
    }
  }

  /// Upserts the FCM token into the `public.user_device_tokens` table.
  Future<void> _upsertToken(String token) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final platform = defaultTargetPlatform == TargetPlatform.iOS
          ? 'ios'
          : 'android';

      await _supabase.from('user_device_tokens').upsert(
        {
          'user_id': user.id,
          'fcm_token': token,
          'device_type': platform,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'fcm_token',
      );
      debugPrint('[FcmTokenService] FCM token synced with Supabase successfully.');
    } catch (e) {
      debugPrint('[FcmTokenService] Failed to upsert token into Supabase: $e');
    }
  }

  /// Removes the device token on user logout.
  Future<void> clearToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await _supabase
            .from('user_device_tokens')
            .delete()
            .match({'fcm_token': token});
      }
    } catch (e) {
      debugPrint('[FcmTokenService] Failed to clear token on sign-out: $e');
    }
  }

  void dispose() {
    _tokenRefreshSub?.cancel();
  }
}
