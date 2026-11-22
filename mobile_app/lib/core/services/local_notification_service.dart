import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../features/notifications/domain/entities/app_notification.dart';

/// Singleton service responsible for native pop-up (heads-up) notifications.
///
/// Adheres strictly to Clean Architecture (lib/core/services/).
class LocalNotificationService {
  static final LocalNotificationService instance =
      LocalNotificationService._internal();

  static const String channelId = 'paws_and_found_channel';
  static const String channelName = 'Paws and Found Alerts';
  static const String channelDescription =
      'Notifications for pet sightings, matches, and community updates';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _isInitialized = false;

  /// Emits the notification payload string when a user taps a native banner.
  final ValueNotifier<String?> onNotificationTapped = ValueNotifier<String?>(null);

  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  LocalNotificationService._internal()
      : _plugin = FlutterLocalNotificationsPlugin();

  /// Initializes the local notification plugin and configures the Android channel.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            onNotificationTapped.value = payload;
          }
        },
      );

      // Create high-importance notification channel for Android heads-up popups
      final androidPlatform = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlatform != null) {
        const channel = AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDescription,
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
        );
        await androidPlatform.createNotificationChannel(channel);
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('[LocalNotificationService] Initialization error: $e');
    }
  }

  /// Requests notification permissions on Android 13+ and iOS.
  Future<bool> requestPermission() async {
    try {
      // Android 13+ (API 33+) permission request
      final androidPlatform = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlatform != null) {
        final granted =
            await androidPlatform.requestNotificationsPermission() ?? false;
        return granted;
      }

      // iOS permission request
      final iosPlatform = _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosPlatform != null) {
        final granted = await iosPlatform.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
        return granted;
      }
    } catch (e) {
      debugPrint('[LocalNotificationService] Permission request error: $e');
    }
    return false;
  }

  /// Displays a native heads-up pop-up notification from an [AppNotification].
  Future<void> showAppNotification(AppNotification notification) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final title = _resolveTitle(notification.type);
      final body = notification.message;
      final payload = (notification.type == 'claim_request' || notification.type == 'claim_update') &&
              notification.relatedReportId != null &&
              notification.relatedReportId!.isNotEmpty
          ? '/claim?reportId=${notification.relatedReportId}'
          : (notification.relatedReportId ??
              notification.relatedMatchId ??
              notification.id);

      // Deterministic non-negative notification ID from UUID
      final id = notification.id.hashCode & 0x7FFFFFFF;

      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'Paws and Found Alert',
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      await _plugin.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('[LocalNotificationService] showAppNotification error: $e');
    }
  }

  /// Resolves an intuitive title based on the notification type.
  String _resolveTitle(String type) {
    switch (type.toLowerCase()) {
      case 'match_found':
        return 'Possible Pet Match Found! 🐾';
      case 'report_nearby':
        return 'New Pet Sighting Nearby 📍';
      case 'pet_safe':
        return 'Pet Recovered & Safe! 🎉';
      case 'report_update':
        return 'Update on Sighting Report 📋';
      case 'status_update':
        return 'Account Status Update ℹ️';
      case 'welcome':
        return 'Welcome to Paws and Found! 🐾';
      case 'claim_request':
        return 'Pet Claim Request Received 🤝';
      case 'claim_update':
        return 'Recovery Pipeline Update 🐾';
      default:
        return 'Paws and Found Notification 🐾';
    }
  }
}
