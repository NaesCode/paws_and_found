import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';

/// Pinned top header for the Profile screen.
///
/// Implemented as a real [PreferredSizeWidget] so [ProfileSetupPage] can
/// assign it to [Scaffold.appBar]. This lets it automatically inherit the
/// app-wide [AppBarTheme] (background color, title font, icon color,
/// status bar style) defined in [AppTheme.light].
class ProfileHeader extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onEditPressed;

  const ProfileHeader({
    super.key,
    this.onEditPressed,
  });

  /// Standard AppBar height — matches every other page's header height.
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      // Title inherits Nunito Sans 22px bold white from AppBarTheme automatically.
      title: const Text('Profile Account'),

      // Three-dot overflow menu — same pattern as before, now as an action.
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (value) async {
            if (value == 'admin') {
              context.push('/admin');
            } else if (value == 'edit') {
              onEditPressed?.call();
            } else if (value == 'logout') {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                context.go('/login');
              }
            }
          },
          itemBuilder: (context) {
            final user = Supabase.instance.client.auth.currentUser;
            final isAdmin = user != null &&
                (user.appMetadata['is_admin'] == true ||
                 user.appMetadata['role'] == 'admin' ||
                 user.appMetadata['role'] == 'ADMIN');

            return [
              if (isAdmin)
                const PopupMenuItem(
                  value: 'admin',
                  child: Row(
                    children: [
                      Icon(Icons.admin_panel_settings_outlined, size: 18, color: AppColors.primary),
                      SizedBox(width: 10),
                      Text('Admin Console', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                    SizedBox(width: 10),
                    Text('Edit Profile', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: AppColors.contrast2),
                    SizedBox(width: 10),
                    Text('Log Out', style: TextStyle(fontSize: 14, color: AppColors.contrast2)),
                  ],
                ),
              ),
            ];
          },
        ),
      ],
    );
  }
}
