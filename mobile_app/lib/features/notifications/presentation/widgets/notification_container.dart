import 'package:flutter/material.dart';

class NotificationContainer extends StatelessWidget {
  /// The contents inside the container (to be built later)
  final Widget child;

  /// Toggles between the unread tint and the read (white) background
  final bool isUnread;

  /// Optional tap action
  final VoidCallback? onTap;

  const NotificationContainer({
    super.key,
    required this.child,
    this.isUnread = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Unread items have a soft slate/blue tint, read items are pure white
    final backgroundColor = isUnread 
        ? const Color(0xFFF8FAFC) 
        : Colors.white;

    return Material(
      color: backgroundColor,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          decoration: const BoxDecoration(
            // Subtle bottom divider border
            border: Border(
              bottom: BorderSide(
                color: Color(0xFFF1F5F9), 
                width: 1.0,
              ),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

