import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/profile/presentation/pages/profile_setup_page.dart';
import '../../features/feed/presentation/pages/feed_page.dart';
import '../../features/feed/presentation/pages/general_reports_page.dart';

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
    ///      a direct Supabase profile query after login).
    ///   3. Otherwise → allow the navigation to proceed.
    // redirect: (context, state) {
    //   final session = Supabase.instance.client.auth.currentSession;
    //   final isLoggedIn = session != null;
    //   final isOnLoginPage = state.matchedLocation == '/login';

    //   // Not logged in and NOT heading to login → force login
    //   if (!isLoggedIn && !isOnLoginPage) {
    //     return '/login';
    //   }

    //   // Already logged in and heading to login → send to home
    //   if (isLoggedIn && isOnLoginPage) {
    //     return '/home';
    //   }

    //   // All good — no redirect needed
    //   return null;
    // },

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

      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileSetupPage(),
      ),

      // Standalone notifications route (for future push notification deep-links)
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: '/feed',
        name: 'feed',
        builder: (context, state) => const FeedPage(),
      ),
      
      GoRoute(
        path: '/general_reports',
        name: 'general_reports',
        builder: (context, state) => const GeneralReports(),
      ),

      // GoRoute(
      //   path: '/personal_reports',
      //   name: 'personal_reports',
      //   builder: (context, state) => const GeneralReports(),
      // )
    ],
  );
}
