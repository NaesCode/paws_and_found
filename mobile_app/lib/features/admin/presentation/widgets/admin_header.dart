import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/atoms/app_logo.dart';
import '../../../../shared/molecules/app_overflow_menu.dart';

/// Top bar header matching SDD Screens 09 & 10 with clinical veterinary branding.
///
/// Features:
/// - Exit / Back to App navigation button
/// - Standardized 32px AppLogo atom
/// - Clear, unblocked title with clinical 'ADMIN' badge
/// - Standardized AppOverflowMenu with 'Exit Admin', 'Settings', and 'Log Out'
class AdminHeader extends StatelessWidget {
  final String title;
  final int selectedTabIndex; // 0 for Users, 1 for Posts, 2 for Analytics
  final ValueChanged<int>? onTabChanged;
  final VoidCallback? onLogout;
  final VoidCallback? onExitAdmin;

  const AdminHeader({
    super.key,
    required this.title,
    this.selectedTabIndex = 0,
    this.onTabChanged,
    this.onLogout,
    this.onExitAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          // 1. Exit / Back to App Icon Button
          InkWell(
            key: const Key('admin_exit_button'),
            borderRadius: BorderRadius.circular(8.0),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: () {
              if (onExitAdmin != null) {
                onExitAdmin!();
              } else if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                try {
                  context.go('/map');
                } catch (_) {}
              }
            },
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 22.0,
                color: AppColors.darkSlate,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 2. App Logo (32px standardized atom)
          const AppLogo(size: 32),
          const SizedBox(width: 10),

          // 3. Screen Title & ADMIN Badge
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Nunito Sans',
                      color: AppColors.darkCharcoal,
                      fontWeight: FontWeight.w800,
                      fontSize: 18.0,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'ADMIN',
                    style: TextStyle(
                      fontFamily: 'Nunito Sans',
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 10.0,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. Standardized Overflow Menu
          AppOverflowMenu(
            key: const Key('admin_overflow_menu'),
            isAdminPage: true,
            iconColor: AppColors.darkSlate,
            onExitPressed: onExitAdmin,
            onLogoutPressed: onLogout,
          ),
        ],
      ),
    );
  }
}
