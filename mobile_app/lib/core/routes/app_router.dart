import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/login', // Start at the login page for now
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
    ],
  );
}
