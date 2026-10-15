import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:paws_and_found/core/theme/app_colors.dart';
import 'package:paws_and_found/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:paws_and_found/features/notifications/presentation/pages/notifications_page.dart';
import 'package:paws_and_found/features/profile/presentation/pages/profile_setup_page.dart';

/// The main shell of the authenticated app experience.
///
/// Houses the bottom navigation bar with four tabs:
///   0 — Map        (stub — Phase 5 deep implementation)
///   1 — Reports    (stub — Phase 5 deep implementation)
///   2 — Alerts     (functional — NotificationsPage)
///   3 — Profile    (functional — ProfileSetupPage)
///
/// This page itself holds NO business logic.  Each tab is a self-contained
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
        return const _MapStub();
      case 1:
        return const _ReportsStub();
      case 2:
        // Pass the repo so the page can refresh the badge after "mark all read".
        return NotificationsPage(
          repository: NotificationRepositoryImpl(),
        );
      case 3:
        return const ProfileSetupPage();
      default:
        return const _MapStub();
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
        children: List.generate(4, _pageFor),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withValues(alpha: 0.15),
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          // Refresh badge whenever the user switches away from notifications.
          if (index != 2) _fetchUnreadCount();
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded, color: AppColors.primary),
            label: 'Map',
          ),
          const NavigationDestination(
            icon: Icon(Icons.pets_outlined),
            selectedIcon: Icon(Icons.pets_rounded, color: AppColors.primary),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _unreadCount > 0,
              label: Text('$_unreadCount'),
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: _unreadCount > 0,
              label: Text('$_unreadCount'),
              child: const Icon(Icons.notifications_rounded, color: AppColors.primary),
            ),
            label: 'Alerts',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stub pages (placeholders until deep implementation in later sprints)
// ---------------------------------------------------------------------------

/// Placeholder for the Map tab.
///
/// TODO(Phase 5): Replace with a real map widget (flutter_map / Google Maps)
/// that calls the `nearby_reports` RPC and renders pins.
class _MapStub extends StatelessWidget {
  const _MapStub();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nearby Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_rounded, size: 72, color: AppColors.primary),
            SizedBox(height: 20),
            Text(
              'Map View',
              style: TextStyle(
                fontFamily: 'Caveat',
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.darkCharcoal,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Interactive pet report map\ncoming in the next sprint.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.text3, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

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
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Report Sighting — coming soon!'),
              backgroundColor: AppColors.primary,
            ),
          );
        },
      ),
    );
  }
}
