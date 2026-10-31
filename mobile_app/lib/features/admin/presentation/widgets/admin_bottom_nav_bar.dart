import 'package:flutter/material.dart';
import '../../../../core/theme/wireframe_colors.dart';

/// Bottom Navigation Bar for Admin section allowing switching between
/// User Management (Tab 0) and Post Management (Tab 1).
class AdminBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const AdminBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: WireframeColors.surface,
        border: Border(
          top: BorderSide(
            color: WireframeColors.border,
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              // Tab 0: User Management
              Expanded(
                child: _buildNavItem(
                  key: const Key('admin_nav_users'),
                  index: 0,
                  label: 'User Management',
                  activeIcon: Icons.people_alt_rounded,
                  inactiveIcon: Icons.people_alt_outlined,
                ),
              ),

              // Vertical divider between tabs
              Container(
                height: 24,
                width: 1,
                color: WireframeColors.divider,
              ),

              // Tab 1: Post Management
              Expanded(
                child: _buildNavItem(
                  key: const Key('admin_nav_posts'),
                  index: 1,
                  label: 'Post Management',
                  activeIcon: Icons.article_rounded,
                  inactiveIcon: Icons.article_outlined,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required Key key,
    required int index,
    required String label,
    required IconData activeIcon,
    required IconData inactiveIcon,
  }) {
    final isSelected = currentIndex == index;
    final color =
        isSelected ? WireframeColors.primaryDark : WireframeColors.textMuted;

    return InkWell(
      key: key,
      onTap: () => onTabSelected(index),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: color,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12.0,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

