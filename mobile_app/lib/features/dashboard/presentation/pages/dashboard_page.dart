import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:paws_and_found/core/services/audio_alert_service.dart';
import 'package:paws_and_found/core/services/local_notification_service.dart';
import 'package:paws_and_found/core/services/user_restriction_service.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';
import 'package:paws_and_found/features/map/presentation/pages/map_page.dart';
import 'package:paws_and_found/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:paws_and_found/features/notifications/domain/entities/app_notification.dart';
import 'package:paws_and_found/features/notifications/presentation/pages/notifications_page.dart';
import 'package:paws_and_found/features/profile/presentation/pages/profile_setup_page.dart';
import 'package:paws_and_found/features/report/presentation/pages/camera_report_page.dart';
import 'package:paws_and_found/shared/organisms/account_suspended_view.dart';
import 'package:paws_and_found/shared/organisms/custom_app_bar.dart';
import 'package:paws_and_found/features/feed/presentation/pages/feed_page.dart';

/// The main shell of the authenticated app experience.
///
/// Houses the custom bottom navigation bar with five tabs:
///   0 — Map        (stub — Phase 5 deep implementation)
///   1 — Feed / FYP (function - FeedPage)
///   2 — Camera     (stub — quick pet sighting camera)
///   3 — Profile    (functional — ProfileSetupPage)
///   4 — Alerts     (functional — NotificationsPage)
///
/// This page itself holds NO business logic. Each tab is a self-contained
/// page that manages its own state.
class DashboardPage extends StatefulWidget {
  /// Allows injection of the starting tab index (e.g. from a deep-link).
  final int initialIndex;
  final UserRestrictionService? restrictionService;

  /// Allows opening the Feed tab with a specific report highlighted / isolated.
  final String? initialFeedReportId;

  const DashboardPage({
    super.key,
    this.initialIndex = 0,
    this.restrictionService,
    this.initialFeedReportId,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late int _currentIndex;
  final Set<int> _visitedTabs = {};
  late final UserRestrictionService _restrictionService;
  bool _isSuspended = false;

  String? _selectedMapReportId;
  LatLng? _selectedMapCenter;
  String? _selectedFeedReportId;

  // Notification badge count — fetched once on mount and kept in sync via stream.
  int _unreadCount = 0;
  StreamSubscription<int>? _unreadSub;
  StreamSubscription<List<AppNotification>>? _notifSub;
  String? _lastKnownNotificationId;
  bool _isInitialNotifStream = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _visitedTabs.add(_currentIndex);
    _selectedFeedReportId = widget.initialFeedReportId;
    _restrictionService = widget.restrictionService ?? const UserRestrictionService();
    _isSuspended = _restrictionService.isUserSuspendedSync();
    _checkSuspensionStatus();
    if (!_isSuspended) {
      _fetchUnreadCount();
      _subscribeToUnreadCount();
      _subscribeToNotificationAlerts();
      _initNativeNotifications();
    }
  }

  Future<void> _checkSuspensionStatus() async {
    final suspended = await _restrictionService.isUserSuspended();
    if (mounted && _isSuspended != suspended) {
      setState(() => _isSuspended = suspended);
      if (!suspended) {
        _fetchUnreadCount();
        _subscribeToUnreadCount();
        _subscribeToNotificationAlerts();
        _initNativeNotifications();
      }
    }
  }

  @override
  void didUpdateWidget(covariant DashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      setState(() {
        _currentIndex = widget.initialIndex;
        _visitedTabs.add(widget.initialIndex);
      });
    }
    if (widget.initialFeedReportId != oldWidget.initialFeedReportId &&
        widget.initialFeedReportId != null) {
      setState(() {
        _selectedFeedReportId = widget.initialFeedReportId;
        _currentIndex = 1;
        _visitedTabs.add(1);
      });
    }
  }

  void _initNativeNotifications() {
    try {
      unawaited(LocalNotificationService.instance.requestPermission());
      LocalNotificationService.instance.onNotificationTapped
          .addListener(_onNativeNotificationTapped);
    } catch (_) {}
  }

  void _onNativeNotificationTapped() {
    final payload = LocalNotificationService.instance.onNotificationTapped.value;
    if (payload != null && mounted) {
      if (payload.startsWith('/claim')) {
        context.push(payload);
      } else {
        // Direct navigation to notifications tab upon tapping native heads-up banner
        setState(() => _currentIndex = 4);
      }
    }
  }

  static const String _keyLastAlertedNotificationId = 'last_alerted_notification_id';

  void _subscribeToNotificationAlerts() {
    try {
      _notifSub = NotificationRepositoryImpl()
          .streamNotifications()
          .listen(
            (notifications) async {
              if (!mounted || notifications.isEmpty) return;

              final newest = notifications.first;
              if (_isInitialNotifStream) {
                _isInitialNotifStream = false;
                _lastKnownNotificationId = newest.id;

                // Emphasize unread notification received while logged out (within the last 24h)
                await _checkAndAlertMissedNotification(newest);
                return;
              }

              // Play alert and display native pop-up notification for new unread alert arriving live
              if (newest.id != _lastKnownNotificationId && !newest.isRead) {
                _lastKnownNotificationId = newest.id;
                await _recordAlertedNotificationId(newest.id);
                AudioAlertService.instance.playNotificationAlertForNotification(newest);
                LocalNotificationService.instance.showAppNotification(newest);
              }
            },
            onError: (_) {},
          );
    } catch (_) {}
  }

  /// Checks if the latest notification arrived while user was logged out / app closed,
  /// and triggers a heads-up pop-up alert if it was received within the day.
  Future<void> _checkAndAlertMissedNotification(AppNotification notification) async {
    try {
      if (notification.isRead) return;

      // Only re-notify if within the day (last 24 hours)
      final age = DateTime.now().difference(notification.createdAt);
      if (age.inHours >= 24) return;

      final prefs = await SharedPreferences.getInstance();
      final lastAlertedId = prefs.getString(_keyLastAlertedNotificationId);

      // If we haven't already alerted this notification ID
      if (lastAlertedId != notification.id) {
        await prefs.setString(_keyLastAlertedNotificationId, notification.id);
        if (mounted) {
          AudioAlertService.instance.playNotificationAlertForNotification(notification);
          LocalNotificationService.instance.showAppNotification(notification);
        }
      }
    } catch (_) {}
  }

  Future<void> _recordAlertedNotificationId(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastAlertedNotificationId, id);
    } catch (_) {}
  }

  void _subscribeToUnreadCount() {
    try {
      _unreadSub = NotificationRepositoryImpl()
          .streamUnreadCount()
          .listen(
            (count) {
              if (mounted) setState(() => _unreadCount = count);
            },
            onError: (_) {},
          );
    } catch (_) {}
  }

  @override
  void dispose() {
    _unreadSub?.cancel();
    _notifSub?.cancel();
    try {
      LocalNotificationService.instance.onNotificationTapped
          .removeListener(_onNativeNotificationTapped);
    } catch (_) {}
    super.dispose();
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final count = await NotificationRepositoryImpl().getUnreadCount();
      if (mounted) setState(() => _unreadCount = count);
    } catch (_) {
      // Non-critical — badge simply stays at 0 if the query fails.
    }
  }

  // ---------------------------------------------------------------------------
  // Tab pages
  // ---------------------------------------------------------------------------

  /// Returns the page widget for [index].
  /// Pages are created on demand; IndexedStack keeps them alive once visited.
  Widget _pageFor(int index) {
    switch (index) {
      case 0:
        return MapPage(
          showBottomNavPlaceholder: false,
          initialReportId: _selectedMapReportId,
          initialCenter: _selectedMapCenter,
        );
      case 1:
        return FeedPage(
          isolatedReportId: _selectedFeedReportId,
          onClearIsolation: () {
            setState(() {
              _selectedFeedReportId = null;
            });
          },
        );
      case 2:
        return CameraReportPage(
          showBottomNavPlaceholder: false,
          isActiveTab: _currentIndex == 2,
        );
      case 3:
        return const ProfileSetupPage();
      case 4:
        return NotificationsPage(
          repository: NotificationRepositoryImpl(),
          isActiveTab: _currentIndex == 4,
          showBottomNavPlaceholder: false,
          onViewOnMap: (reportId, lat, lng) {
            setState(() {
              _selectedMapReportId = reportId;
              if (lat != null && lng != null) {
                _selectedMapCenter = LatLng(lat, lng);
              }
              _currentIndex = 0;
            });
          },
          onViewInFeed: (reportId) {
            // Switch to Feed tab and isolate the specific post
            setState(() {
              _selectedFeedReportId = reportId;
              _currentIndex = 1;
              _visitedTabs.add(1);
            });
          },
        );
      default:
        return const MapPage(showBottomNavPlaceholder: false);
    }
  }

  Future<void> _handleRefreshStatus() async {
    final suspended = await _restrictionService.isUserSuspended();
    if (!mounted) return;
    setState(() => _isSuspended = suspended);
    if (!suspended) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account privileges restored!'),
          backgroundColor: AppColors.statusSafe,
        ),
      );
    }
  }

  Future<void> _handleSignOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
    if (!mounted) return;
    context.go('/login');
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_isSuspended) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: AccountSuspendedView(
            onRefreshStatus: _handleRefreshStatus,
            onSignOut: _handleSignOut,
          ),
        ),
      );
    }

    return Scaffold(
      // IndexedStack keeps all tab pages alive (no re-mount on tab switch).
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(
          5,
          (i) => _visitedTabs.contains(i) ? _pageFor(i) : const SizedBox.shrink(),
        ),
      ),
      bottomNavigationBar: CustomAppBar(
        currentIndex: _currentIndex,
        hasUnreadNotifications: _unreadCount > 0,
        onTabSelected: (index) async {
          if (_isSuspended) return;
          await _checkSuspensionStatus();
          if (_isSuspended) return;
          setState(() {
            _currentIndex = index;
            _visitedTabs.add(index);
          });
          _fetchUnreadCount();
        },
      ),
    );
  }
}
