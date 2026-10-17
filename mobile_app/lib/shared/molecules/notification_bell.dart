import 'package:flutter/material.dart';

class NotificationBell extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isActive;
  final bool hasUnread; // Shows a red dot when unread notifications exist

  const NotificationBell({
    super.key,
    required this.onPressed,
    this.isActive = false,
    this.hasUnread = false,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF374151); // Dark slate color from reference

    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: isActive ? activeColor : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.notifications_none,
                  color: isActive ? Colors.white : Colors.black87,
                  size: 24,
                ),
                // Red badge if there are unread notifications
                if (hasUnread)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Fixed height to prevent layout jumps when the active dot appears/disappears
          SizedBox(
            height: 12,
            child: isActive
                ? Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: activeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}