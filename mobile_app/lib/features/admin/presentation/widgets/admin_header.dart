import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/wireframe_colors.dart';

/// Top bar header matching SDD Screens 09 & 10.
///
/// Features:
/// - Dark rounded-square icon with bold 'A'
/// - Clear, unblocked title ("User Management" or "Post Management")
/// - Direct Logout button triggering session sign out or custom onLogout callback.
class AdminHeader extends StatelessWidget {
  final String title;
  final int selectedTabIndex; // 0 for Users, 1 for Posts
  final ValueChanged<int>? onTabChanged;
  final VoidCallback? onLogout;

  const AdminHeader({
    super.key,
    required this.title,
    this.selectedTabIndex = 0,
    this.onTabChanged,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          // 1. Dark rounded-square icon with 'A'
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: WireframeColors.primaryDark,
              borderRadius: BorderRadius.circular(8.0),
            ),
            alignment: Alignment.center,
            child: const Text(
              'A',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16.0,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // 2. Static Title (Fully visible, clean, no dropdown)
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: WireframeColors.primaryDark,
                fontWeight: FontWeight.w800,
                fontSize: 18.0,
                letterSpacing: -0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),

          // 3. Direct Logout Button
          InkWell(
            key: const Key('admin_logout_button'),
            onTap: () async {
              if (onLogout != null) {
                onLogout!();
              } else {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) {
                  context.go('/login');
                }
              }
            },
            borderRadius: BorderRadius.circular(8.0),
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              decoration: BoxDecoration(
                color: WireframeColors.primaryDark,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.logout_rounded,
                    size: 15,
                    color: Colors.white,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Log Out',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
