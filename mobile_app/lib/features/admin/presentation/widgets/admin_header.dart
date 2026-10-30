import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/wireframe_colors.dart';

/// Top bar header matching SDD Screens 09 & 10.
///
/// Features:
/// - Dark rounded-square icon with bold 'A'
/// - Interactive Title Dropdown Selector ("User Management ▾" or "Post Management ▾")
///   providing full unblocked title visibility and smooth transitions between sections
/// - Dark slate "ADMIN" rectangle button with an embedded circular button
///   that triggers a dropdown menu with the option to Log Out.
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

          // 2. Interactive Title Dropdown Selector (Fully visible, never truncated)
          Expanded(
            child: _buildTitleDropdown(context),
          ),
          const SizedBox(width: 8),

          // 3. Admin rectangle button with a circular dropdown button
          _buildAdminDropdownButton(context),
        ],
      ),
    );
  }

  Widget _buildTitleDropdown(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
      ),
      child: PopupMenuButton<int>(
        tooltip: 'Switch Management Section',
        padding: EdgeInsets.zero,
        offset: const Offset(0, 38),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: WireframeColors.border, width: 1.0),
        ),
        elevation: 3,
        color: Colors.white,
        onSelected: (int index) {
          if (index != selectedTabIndex) {
            onTabChanged?.call(index);
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                title,
                style: const TextStyle(
                  color: WireframeColors.primaryDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 17.0,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.all(2.0),
              decoration: BoxDecoration(
                color: WireframeColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: WireframeColors.primaryDark,
              ),
            ),
          ],
        ),
        itemBuilder: (context) => [
          PopupMenuItem<int>(
            value: 0,
            height: 44,
            child: Row(
              children: [
                Icon(
                  Icons.people_alt_outlined,
                  size: 18,
                  color: selectedTabIndex == 0 ? WireframeColors.primaryDark : WireframeColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'User Management',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: selectedTabIndex == 0 ? FontWeight.w700 : FontWeight.w500,
                      color: selectedTabIndex == 0 ? WireframeColors.primaryDark : WireframeColors.textPrimary,
                    ),
                  ),
                ),
                if (selectedTabIndex == 0)
                  const Icon(Icons.check_rounded, size: 18, color: WireframeColors.primaryDark),
              ],
            ),
          ),
          const PopupMenuDivider(height: 1),
          PopupMenuItem<int>(
            value: 1,
            height: 44,
            child: Row(
              children: [
                Icon(
                  Icons.article_outlined,
                  size: 18,
                  color: selectedTabIndex == 1 ? WireframeColors.primaryDark : WireframeColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Post Management',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: selectedTabIndex == 1 ? FontWeight.w700 : FontWeight.w500,
                      color: selectedTabIndex == 1 ? WireframeColors.primaryDark : WireframeColors.textPrimary,
                    ),
                  ),
                ),
                if (selectedTabIndex == 1)
                  const Icon(Icons.check_rounded, size: 18, color: WireframeColors.primaryDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminDropdownButton(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.only(left: 8.0, right: 3.0),
      decoration: BoxDecoration(
        color: WireframeColors.primaryDark,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'ADMIN',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 10.5,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(width: 4),

          // Circular button with dropdown
          Theme(
            data: Theme.of(context).copyWith(
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
            ),
            child: PopupMenuButton<String>(
              tooltip: 'Admin Menu',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              offset: const Offset(0, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              icon: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 18,
                  color: WireframeColors.primaryDark,
                ),
              ),
              onSelected: (value) async {
                if (value == 'logout') {
                  if (onLogout != null) {
                    onLogout!();
                  } else {
                    await Supabase.instance.client.auth.signOut();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  }
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  enabled: false,
                  height: 36,
                  child: Row(
                    children: [
                      Icon(Icons.shield_outlined, size: 16, color: WireframeColors.textSecondary),
                      SizedBox(width: 8),
                      Text(
                        'Administrator',
                        style: TextStyle(
                          color: WireframeColors.textSecondary,
                          fontSize: 12.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(height: 1),
                const PopupMenuItem(
                  value: 'logout',
                  height: 40,
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, size: 18, color: Colors.redAccent),
                      SizedBox(width: 8),
                      Text(
                        'Log Out',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 13.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
