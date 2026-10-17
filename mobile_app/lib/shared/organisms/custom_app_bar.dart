import 'package:flutter/material.dart';

import '../molecules/camerafound_icon.dart';
import '../molecules/fyp_icon.dart';
import '../molecules/map_icon.dart';
import '../molecules/notification_bell.dart';
import '../molecules/profile_icon.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Navigation indexes:
  /// 0 = Map, 1 = Feed (FYP), 2 = Camera, 3 = Profile, 4 = Notification
  final int currentIndex;
  
  /// Callback when one of the navigation icons is tapped
  final Function(int) onTabSelected;
  
  /// Optional additional callback specifically for the notification bell
  final VoidCallback? onNotificationPressed;
  
  /// Whether the notification bell should show a red dot
  final bool hasUnreadNotifications;

  const CustomAppBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    this.onNotificationPressed,
    this.hasUnreadNotifications = false,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        height: preferredSize.height,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        // Using Row with spaceBetween to evenly distribute the molecules
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            MapIcon(
              isActive: currentIndex == 0,
              onPressed: () => onTabSelected(0),
            ),
            FypIcon(
              isActive: currentIndex == 1,
              onPressed: () => onTabSelected(1),
            ),
            CameraFoundIcon(
              isActive: currentIndex == 2,
              onPressed: () => onTabSelected(2),
            ),
            ProfileIcon(
              isActive: currentIndex == 3,
              onPressed: () => onTabSelected(3),
            ),
            NotificationBell(
              isActive: currentIndex == 4,
              hasUnread: hasUnreadNotifications,
              onPressed: () {
                onTabSelected(4);
                onNotificationPressed?.call();
              },
            ),
          ],
        ),
      ),
    );
  }

  // Implementing PreferredSizeWidget requires this. 
  // 70.0 gives enough room for the icons and the active dot below them.
  @override
  Size get preferredSize => const Size.fromHeight(70.0);
}
