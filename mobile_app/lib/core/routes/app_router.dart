import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/admin/presentation/pages/admin_analytics_page.dart';
import '../../features/admin/presentation/pages/admin_page.dart';
import '../../features/admin/presentation/pages/admin_posts_page.dart';
import '../../features/admin/presentation/pages/admin_users_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/map/presentation/pages/map_page.dart';
import '../../features/report/presentation/pages/camera_report_page.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/login',

    /// Global redirect guard.
    ///
    /// Runs before every navigation attempt.
    /// Rules:
    ///   1. If user is NOT logged in and not heading to '/login' → redirect to '/login'.
    ///   2. If user IS logged in and tries to reach '/login':
    ///      - If admin → redirect to '/admin'.
    ///      - Otherwise → redirect to '/home'.
    ///   3. If user attempts to reach '/admin' routes:
    ///      - Must be logged in AND have admin claims in app_metadata.
    ///      - Otherwise → redirect to '/home' (or '/login' if not authenticated).
    ///   4. Otherwise → allow navigation.
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final user = Supabase.instance.client.auth.currentUser;

      final isHeadingToLogin = state.matchedLocation == '/login';
      final isHeadingToAdmin = state.matchedLocation.startsWith('/admin');

      // 1. Not logged in and NOT heading to login → force login
      if (!isLoggedIn && !isHeadingToLogin) {
        ScaffoldMessenger.of(context).clearSnackBars();
        return '/login';
      }

      // Check strictly against tamper-proof app_metadata (Method 1)
      final isAdmin = user != null &&
          (user.appMetadata['is_admin'] == true ||
           user.appMetadata['role'] == 'admin' ||
           user.appMetadata['role'] == 'ADMIN');

      // 2. Clear any lingering snackbars when heading to login
      if (isHeadingToLogin) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }

      // 3. Already logged in and heading to login → send to respective home
      if (isLoggedIn && isHeadingToLogin) {
        return isAdmin ? '/admin' : '/home';
      }

      // 4. Admin Access Gate: Only authenticated admins can access /admin
      if (isHeadingToAdmin) {
        if (!isLoggedIn) {
          return '/login';
        }
        if (!isAdmin) {
          // Non-admin attempting to access /admin -> redirect to user home
          return '/home';
        }
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
        builder: (context, state) => const DashboardPage(initialIndex: 4),
      ),

      // Notifications tab route (keeps DashboardPage shell & persistent navigation bar active)
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const DashboardPage(initialIndex: 4),
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
        builder: (context, state) {
          final threadId = state.uri.queryParameters['threadId'];
          final petName = state.uri.queryParameters['petName'];
          final status = state.uri.queryParameters['status'];
          return CameraReportPage(
            showBottomNavPlaceholder: true,
            threadId: threadId,
            threadPetName: petName,
            defaultStatus: status,
          );
        },
      ),

      GoRoute(
        path: '/report',
        name: 'report',
        builder: (context, state) {
          final threadId = state.uri.queryParameters['threadId'];
          final petName = state.uri.queryParameters['petName'];
          final status = state.uri.queryParameters['status'];
          return CameraReportPage(
            showBottomNavPlaceholder: true,
            threadId: threadId,
            threadPetName: petName,
            defaultStatus: status,
          );
        },
      ),
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (context, state) {
          final tabStr = state.uri.queryParameters['tab'];
          final initialTab =
              tabStr == 'analytics' ? 2 : (tabStr == 'posts' ? 1 : 0);
          return AdminPage(initialTabIndex: initialTab);
        },
      ),
      GoRoute(
        path: '/admin/users',
        name: 'adminUsers',
        builder: (context, state) => const AdminUsersPage(),
      ),
      GoRoute(
        path: '/admin/posts',
        name: 'adminPosts',
        builder: (context, state) => const AdminPostsPage(),
      ),
      GoRoute(
        path: '/admin/analytics',
        name: 'adminAnalytics',
        builder: (context, state) => const AdminAnalyticsPage(),
      ),
    ],
  );
}
