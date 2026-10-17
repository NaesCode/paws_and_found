import 'package:flutter/material.dart';
import '../../core/theme/wireframe_colors.dart';

/// A wireframe placeholder bottom navigation bar organism.
///
/// Features 5 navigation item placeholders matching the SDD wireframe:
/// 0: Map (active with indicator dot)
/// 1: Feed
/// 2: Camera
/// 3: Profile
/// 4: Alerts
///
/// Adheres to Atomic Design: dumb, stateless UI element relying purely on
/// passed properties and callbacks.
class WireframeBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const WireframeBottomNavBar({
    super.key,
    this.currentIndex = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: WireframeColors.surface,
        border: Border(
          top: BorderSide(color: WireframeColors.borderLight, width: 1.0),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              index: 0,
              icon: Icons.location_on_rounded,
              isActive: currentIndex == 0,
              hasIndicator: true,
            ),
            _buildNavItem(
              index: 1,
              icon: Icons.menu_rounded,
              isActive: currentIndex == 1,
            ),
            _buildNavItem(
              index: 2,
              icon: Icons.camera_alt_outlined,
              isActive: currentIndex == 2,
            ),
            _buildNavItem(
              index: 3,
              icon: Icons.person_outline_rounded,
              isActive: currentIndex == 3,
            ),
            _buildNavItem(
              index: 4,
              icon: Icons.notifications_none_rounded,
              isActive: currentIndex == 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required bool isActive,
    bool hasIndicator = false,
  }) {
    // If it's the center camera item (index 2)
    if (index == 2) {
      return InkWell(
        onTap: onTap != null ? () => onTap!(index) : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 44,
          height: 38,
          decoration: BoxDecoration(
            color: isActive
                ? WireframeColors.primaryDark
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isActive
                ? null
                : Border.all(color: WireframeColors.border, width: 1.0),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 22,
            color: isActive ? Colors.white : WireframeColors.secondarySlate,
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap != null ? () => onTap!(index) : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isActive
                  ? WireframeColors.primaryDark
                  : WireframeColors.secondarySlate,
            ),
            const SizedBox(height: 4),
            // Active indicator dot
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive && hasIndicator
                    ? WireframeColors.primaryDark
                    : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
