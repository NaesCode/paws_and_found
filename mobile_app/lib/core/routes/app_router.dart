import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/map/presentation/pages/map_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/report/presentation/pages/camera_report_page.dart';

class AppRouter {
  static final router = GoRouter(
    // =========================================================================
    // TODO: TESTING ONLY - Launches directly into the map screen on startup
    // so the map pins and pet info modal can be verified immediately.
    // NOTE: MUST BE REVERTED TO '/login' AFTER TESTING.
    // =========================================================================
    initialLocation: '/map',

    /// Global redirect guard.
    ///
    /// Runs before every navigation attempt.
    /// Rules:
    ///   1. Public routes ('/login', '/map') are always accessible.
    ///   2. If the user is NOT logged in and not heading to a public route → redirect to /login.
    ///   3. If the user IS logged in and tries to reach /login → redirect to /home.
    ///   4. Otherwise → allow navigation.
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final isPublicRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/map' ||
          state.matchedLocation == '/camera' ||
          state.matchedLocation == '/report';

      // Not logged in and NOT heading to a public route → force login
      if (!isLoggedIn && !isPublicRoute) {
        ScaffoldMessenger.of(context).clearSnackBars();
        return '/login';
      }

      // Clear any lingering snackbars when heading to login
      if (state.matchedLocation == '/login') {
        ScaffoldMessenger.of(context).clearSnackBars();
      }

      // Already logged in and heading to login → send to home
      if (isLoggedIn && state.matchedLocation == '/login') {
        return '/home';
      }

      // All good — no redirect needed
      return null;
    },

    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),

      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const DashboardPage(),
      ),

      GoRoute(
        path: '/feed',
        name: 'feed',
        builder: (context, state) => const DashboardPage(initialIndex: 1),
      ),

      GoRoute(
        path: '/profile/setup',
        name: 'profileSetup',
        builder: (context, state) => const DashboardPage(initialIndex: 3),
      ),

      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const DashboardPage(initialIndex: 3),
      ),

      // Standalone notifications route (for future push notification deep-links)
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsPage(),
      ),

      // Community Animal Map route with optional query parameters for targeted report pinning
      GoRoute(
        path: '/map',
        name: 'map',
        builder: (context, state) {
          final reportId = state.uri.queryParameters['reportId'];
          final latStr = state.uri.queryParameters['lat'];
          final lngStr = state.uri.queryParameters['lng'];
          LatLng? initialCenter;
          if (latStr != null && lngStr != null) {
            final lat = double.tryParse(latStr);
            final lng = double.tryParse(lngStr);
            if (lat != null && lng != null) {
              initialCenter = LatLng(lat, lng);
            }
          }
          return MapPage(
            showBottomNavPlaceholder: true,
            initialReportId: reportId,
            initialCenter: initialCenter,
          );
        },
      ),

      // Camera and Animal Report Creation route
      GoRoute(
        path: '/camera',
        name: 'camera',
        builder: (context, state) =>
            const CameraReportPage(showBottomNavPlaceholder: true),
      ),

      GoRoute(
        path: '/report',
        name: 'report',
        builder: (context, state) =>
            const CameraReportPage(showBottomNavPlaceholder: true),
      ),
    ],
  );
}
