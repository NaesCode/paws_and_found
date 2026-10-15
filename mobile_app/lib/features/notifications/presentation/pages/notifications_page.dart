import 'package:flutter/material.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';

import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

/// Displays the user's notification inbox.
///
/// Loaded eagerly on first build and refreshable via pull-to-refresh.
/// Each tap marks the tapped item as read; a "Mark all" button clears all.
class NotificationsPage extends StatefulWidget {
  final NotificationRepository? repository;

  const NotificationsPage({super.key, this.repository});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final NotificationRepository _repo;

  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? NotificationRepositoryImpl();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await _repo.getNotifications();
      if (mounted) setState(() => _notifications = items);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markRead(AppNotification n) async {
    if (n.isRead) return;
    await _repo.markRead(n.id);
    if (mounted) {
      setState(() {
        _notifications = _notifications
            .map((x) => x.id == n.id ? _asRead(x) : x)
            .toList();
      });
    }
  }

  Future<void> _markAllRead() async {
    await _repo.markAllRead();
    if (mounted) {
      setState(() {
        _notifications = _notifications.map(_asRead).toList();
      });
    }
  }

  /// Returns a copy of [n] with `isRead = true`.
  /// Because AppNotification is immutable, we re-create it via the model.
  AppNotification _asRead(AppNotification n) {
    return AppNotification(
      id: n.id,
      userId: n.userId,
      type: n.type,
      message: n.message,
      relatedMatchId: n.relatedMatchId,
      isRead: true,
      createdAt: n.createdAt,
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final unread = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.text3),
              const SizedBox(height: 16),
              Text(
                'Could not load notifications.\n$_error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.text3),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              ),
            ],
          ),
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none_rounded, size: 64, color: AppColors.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            const Text(
              'All caught up!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkCharcoal,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You have no notifications yet.',
              style: TextStyle(color: AppColors.text3),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _notifications.length,
        separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
        itemBuilder: (context, index) {
          final n = _notifications[index];
          return _NotificationTile(
            notification: n,
            onTap: () => _markRead(n),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private tile widget
// ---------------------------------------------------------------------------

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  IconData _iconForType(String type) {
    switch (type) {
      case 'match_found':
        return Icons.favorite_rounded;
      case 'report_nearby':
        return Icons.location_on_rounded;
      case 'pet_safe':
        return Icons.check_circle_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'match_found':
        return AppColors.accentOrange;
      case 'report_nearby':
        return AppColors.primary;
      case 'pet_safe':
        return Colors.green;
      default:
        return AppColors.text3;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    final color = _colorForType(notification.type);

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isUnread ? AppColors.primary.withValues(alpha: 0.06) : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon badge
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(_iconForType(notification.type), color: color, size: 22),
            ),
            const SizedBox(width: 14),

            // Message + time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                      color: AppColors.darkCharcoal,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _timeAgo(notification.createdAt),
                    style: const TextStyle(fontSize: 12, color: AppColors.text3),
                  ),
                ],
              ),
            ),

            // Unread dot
            if (isUnread)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 8),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.accentOrange,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

