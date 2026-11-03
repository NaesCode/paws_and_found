import 'dart:async';
import 'package:flutter/material.dart';
import 'package:paws_and_found/features/map/presentation/pages/map_page.dart';
import 'package:paws_and_found/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:paws_and_found/features/notifications/presentation/pages/notifications_page.dart';
import 'package:paws_and_found/features/profile/presentation/pages/profile_setup_page.dart';
import 'package:paws_and_found/features/report/presentation/pages/camera_report_page.dart';
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

  const DashboardPage({super.key, this.initialIndex = 0});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late int _currentIndex;

  // Notification badge count — fetched once on mount and kept in sync via stream.
  int _unreadCount = 0;
  StreamSubscription<int>? _unreadSub;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _fetchUnreadCount();
    _subscribeToUnreadCount();
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
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      setState(() => _currentIndex = widget.initialIndex);
    }
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
        return const MapPage(showBottomNavPlaceholder: false);
      case 1:
        return const FeedPage();
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
        );
      default:
        return const MapPage(showBottomNavPlaceholder: false);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack keeps all tab pages alive (no re-mount on tab switch).
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(5, _pageFor),
      ),
      bottomNavigationBar: CustomAppBar(
        currentIndex: _currentIndex,
        hasUnreadNotifications: _unreadCount > 0,
        onTabSelected: (index) {
          setState(() => _currentIndex = index);
          _fetchUnreadCount();
        },
      ),
    );
  }
}

