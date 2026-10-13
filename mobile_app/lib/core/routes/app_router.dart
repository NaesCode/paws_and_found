import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/profile/presentation/pages/profile_setup_page.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/login',

    /// Global redirect guard.
    ///
    /// Runs before every navigation attempt.
    /// Rules:
    ///   1. If the user is NOT logged in → always redirect to /login.
    ///   2. If the user IS logged in and tries to reach /login → redirect to
    ///      /home (the auth_tray handles the finer profile/home split via
    ///      the Django /api/me/ handshake after login).
    ///   3. Otherwise → allow the navigation to proceed.
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final isOnLoginPage = state.matchedLocation == '/login';

      // Not logged in and NOT heading to login → force login
      if (!isLoggedIn && !isOnLoginPage) {
        return '/login';
      }

      // Already logged in and heading to login → send to home
      if (isLoggedIn && isOnLoginPage) {
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
        path: '/profile/setup',
        name: 'profileSetup',
        builder: (context, state) => const ProfileSetupPage(),
      ),
    ],
  );
}
