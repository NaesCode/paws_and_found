import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:paws_and_found/core/theme/app_colors.dart';
import 'package:paws_and_found/features/map/presentation/pages/map_page.dart';
import 'package:paws_and_found/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:paws_and_found/features/notifications/presentation/pages/notifications_page.dart';
import 'package:paws_and_found/features/profile/presentation/pages/profile_setup_page.dart';
import 'package:paws_and_found/shared/organisms/custom_app_bar.dart';

/// The main shell of the authenticated app experience.
///
/// Houses the custom bottom navigation bar with five tabs:
///   0 — Map        (stub — Phase 5 deep implementation)
///   1 — Feed / FYP (stub — Phase 5 deep implementation)
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

  // Notification badge count — fetched once on mount.
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _fetchUnreadCount();
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
        return const _ReportsStub();
      case 2:
        return const _CameraStub();
      case 3:
        return const ProfileSetupPage();
      case 4:
        return NotificationsPage(
          repository: NotificationRepositoryImpl(),
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
          // Refresh badge whenever the user switches away from notifications.
          if (index != 4) _fetchUnreadCount();
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stub pages (placeholders until deep implementation in later sprints)
// ---------------------------------------------------------------------------

/// Placeholder for the Reports/Feed tab.
///
/// TODO(Phase 5): Replace with a scrollable feed of SightingReport cards
/// loaded from the `nearby_reports` RPC.
class _ReportsStub extends StatelessWidget {
  const _ReportsStub();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pet Reports'),
      ),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pets_rounded, size: 72, color: AppColors.primary),
            SizedBox(height: 20),
            Text(
              'Reports Feed',
              style: TextStyle(
                fontFamily: 'Caveat',
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.darkCharcoal,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Community sighting reports\ncoming in the next sprint.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.text3, height: 1.5),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accentOrange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_a_photo_rounded),
        label: const Text('Report Sighting'),
        onPressed: () => context.push('/camera'),
      ),
    );
  }
}

/// Placeholder for the Camera / Sighting tab.
class _CameraStub extends StatelessWidget {
  const _CameraStub();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Found Pet Camera'),
      ),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.camera_alt_rounded, size: 72, color: AppColors.primary),
            SizedBox(height: 20),
            Text(
              'Camera Scanner',
              style: TextStyle(
                fontFamily: 'Caveat',
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.darkCharcoal,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Snap a picture of a found pet to run AI matching.\nComing soon!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.text3, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}