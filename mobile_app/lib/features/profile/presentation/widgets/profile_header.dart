import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Pinned top header bar showing "Profile Account" with a soft elevation shadow
/// and an unobtrusive logout action button.
class ProfileHeader extends StatelessWidget {
  final VoidCallback? onEditPressed;

  const ProfileHeader({
    super.key,
    this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background1,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Profile Account',
                style: AppTypography.profileTitle,
              ),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: AppColors.text2,
                  size: 22,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) async {
                  if (value == 'edit') {
                    onEditPressed?.call();
                  } else if (value == 'logout') {
                    await Supabase.instance.client.auth.signOut();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  }
                },
                itemBuilder: (context) => [
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

