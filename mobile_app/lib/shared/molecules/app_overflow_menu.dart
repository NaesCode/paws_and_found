import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';

/// A reusable three-dot overflow popup menu molecule for application headers.
///
/// Adheres strictly to Atomic Design (lib/shared/molecules/).
/// Standardized across Map, Feed/Reports, and Profile headers.
class AppOverflowMenu extends StatelessWidget {
  final VoidCallback? onEditPressed;
  final VoidCallback? onSettingsPressed;
  final VoidCallback? onAdminPressed;
  final VoidCallback? onLogoutPressed;

  /// Whether to display the 'Edit Profile' option in the menu.
  ///
  /// Defaults to `true` when [onEditPressed] is provided (i.e. on the Profile screen),
  /// and `false` elsewhere (e.g. Map, Reports headers).
  final bool? showEditProfile;

  const AppOverflowMenu({
    super.key,
    this.onEditPressed,
    this.onSettingsPressed,
    this.onAdminPressed,
    this.onLogoutPressed,
    this.showEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onSelected: (value) async {
        if (value == 'admin') {
          if (onAdminPressed != null) {
            onAdminPressed!();
          } else {
            context.push('/admin');
          }
        } else if (value == 'edit') {
          if (onEditPressed != null) {
            onEditPressed!();
          } else {
            context.go('/profile');
          }
        } else if (value == 'settings') {
          if (onSettingsPressed != null) {
            onSettingsPressed!();
          } else {
            context.push('/settings');
          }
        } else if (value == 'logout') {
          if (onLogoutPressed != null) {
            onLogoutPressed!();
          } else {
            await AuthRepositoryImpl().signOut();
            if (context.mounted) {
              context.go('/login');
            }
          }
        }
      },
      itemBuilder: (context) {
        User? user;
        try {
          user = Supabase.instance.client.auth.currentUser;
        } catch (_) {}
        final isAdmin = user != null &&
            (user.appMetadata['is_admin'] == true ||
             user.appMetadata['role'] == 'admin' ||
             user.appMetadata['role'] == 'ADMIN');

        final canEdit = showEditProfile ?? (onEditPressed != null);

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
          if (canEdit)
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
            value: 'settings',
            child: Row(
              children: [
                Icon(Icons.settings_outlined, size: 18, color: AppColors.primary),
                SizedBox(width: 10),
                Text('Settings', style: TextStyle(fontSize: 14)),
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
    );
  }
}
