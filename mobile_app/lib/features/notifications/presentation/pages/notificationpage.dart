import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/organisms/custom_app_bar.dart';
import '../widgets/notification_container.dart';

class NotificationItemData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool isUnread;

  const NotificationItemData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.isUnread,
  });

  NotificationItemData copyWith({bool? isUnread}) {
    return NotificationItemData(
      title: title,
      subtitle: subtitle,
      icon: icon,
      iconColor: iconColor,
      isUnread: isUnread ?? this.isUnread,
    );
  }
}

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  // Mock data matching the design reference
  late List<NotificationItemData> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = [
      const NotificationItemData(
        title: 'New MISSING report posted 0.8km away',
        subtitle: 'Elm & 3rd · 2m ago',
        icon: Icons.location_on,
        iconColor: Color(0xFFE11D48),
        isUnread: true,
      ),
      const NotificationItemData(
        title: 'AI found a potential match for your pet',
        subtitle: '87% confidence · 20m ago',
        icon: Icons.link_rounded,
        iconColor: Color(0xFF8B5CF6),
        isUnread: true,
      ),
      const NotificationItemData(
        title: 'Sarah replied on report #021',
        subtitle: 'Community Feed · 45m ago',
        icon: Icons.chat_bubble_outline_rounded,
        iconColor: Color(0xFFA855F7),
        isUnread: false,
      ),
      const NotificationItemData(
        title: 'FOUND report near your watch zone',
        subtitle: 'Park Blvd · 1h ago',
        icon: Icons.location_on,
        iconColor: Color(0xFFE11D48),
        isUnread: false,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => n.isUnread).length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: "Notifications" and "X unread"
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    '$unreadCount unread',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Notification List
            Expanded(
              child: ListView.builder(
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final item = _notifications[index];

                  return NotificationContainer(
                    isUnread: item.isUnread,
                    onTap: () {
                      // Tap to mark as read
                      setState(() {
                        _notifications[index] = item.copyWith(isUnread: false);
                      });
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Circular leading icon
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Icon(
                            item.icon,
                            color: item.iconColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Title & Subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.subtitle,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Trailing unread dot
                        if (item.isUnread) ...[
                          const SizedBox(width: 12),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF334155),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // Bottom navigation bar with Notification tab (index 4) highlighted
      bottomNavigationBar: CustomAppBar(
        currentIndex: 4,
        hasUnreadNotifications: unreadCount > 0,
        onTabSelected: (index) {
          if (index != 4) {
            context.go('/home');
          }
        },
      ),
    );
  }
}

