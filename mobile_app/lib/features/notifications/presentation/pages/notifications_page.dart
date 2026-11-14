import 'package:go_router/go_router.dart';
import '../../../../shared/organisms/custom_app_bar.dart';
import '../../../../shared/molecules/paw_loading.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';

import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../widgets/post_details_bottom_sheet.dart';

/// Displays the user's notification inbox.
///
/// Loaded eagerly on first build and refreshable via pull-to-refresh.
/// Each tap marks the tapped item as read and, for post-related notifications,
/// immediately opens the post details view directly.
class NotificationsPage extends StatefulWidget {
  final NotificationRepository? repository;
  final bool isActiveTab;
  final bool showBottomNavPlaceholder;
  final void Function(String reportId, double? lat, double? lng)? onViewOnMap;

  const NotificationsPage({
    super.key,
    this.repository,
    this.isActiveTab = true,
    this.showBottomNavPlaceholder = false,
    this.onViewOnMap,
  });

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late NotificationRepository _repo;

  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription<List<AppNotification>>? _subscription;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? NotificationRepositoryImpl();
    _load();
    _subscribe();
  }

  @override
  void didUpdateWidget(covariant NotificationsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.repository != oldWidget.repository) {
      _repo = widget.repository ?? NotificationRepositoryImpl();
      _subscription?.cancel();
      _subscribe();
    }
    if (!oldWidget.isActiveTab && widget.isActiveTab) {
      _load(isSilent: true);
    }
  }

  void _subscribe() {
    try {
      _subscription = _repo.streamNotifications().listen(
        (items) {
          if (mounted) {
            setState(() {
              _notifications = items;
              _isLoading = false;
              _error = null;
            });
          }
        },
        onError: (_) {},
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _load({bool isSilent = false}) async {
    if (!isSilent || _notifications.isEmpty) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final items = await _repo.getNotifications();
      if (mounted) setState(() => _notifications = items);
    } catch (e) {
      if (mounted && _notifications.isEmpty) setState(() => _error = e.toString());
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

  Future<void> _handleNotificationTap(AppNotification n) async {
    // 1. Mark as read
    await _markRead(n);

    // 2. If post-related, open post details directly
    if (n.isPostRelated && mounted) {
      PostDetailsBottomSheet.show(
        context: context,
        notification: n,
        repository: _repo,
        onViewOnMap: widget.onViewOnMap,
      );
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
  AppNotification _asRead(AppNotification n) {
    return AppNotification(
      id: n.id,
      userId: n.userId,
      type: n.type,
      message: n.message,
      relatedMatchId: n.relatedMatchId,
      relatedReportId: n.relatedReportId,
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
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
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
      bottomNavigationBar: widget.showBottomNavPlaceholder
          ? CustomAppBar(
              currentIndex: 4,
              hasUnreadNotifications: unread > 0,
              onTabSelected: (index) {
                switch (index) {
                  case 0:
                    context.go('/map');
                    break;
                  case 1:
                    context.go('/feed');
                    break;
                  case 2:
                    context.go('/camera');
                    break;
                  case 3:
                    context.go('/profile');
                    break;
                  case 4:
                    // Already on notifications
                    break;
                }
              },
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading && _notifications.isEmpty) {
      return const Center(
        child: PawLoadingIndicator(message: 'Checking notifications...'),
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
            onTap: () => _handleNotificationTap(n),
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
      case 'welcome':
        return Icons.pets_rounded;
      case 'match_found':
        return Icons.favorite_rounded;
      case 'report_nearby':
        return Icons.location_on_rounded;
      case 'pet_safe':
        return Icons.check_circle_rounded;
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'suspension':
        return Icons.block_rounded;
      case 'status_update':
        return Icons.verified_user_outlined;
      case 'match_confirmed':
        return Icons.celebration_rounded;
      case 'report_update':
        return Icons.campaign_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'welcome':
        return AppColors.primary;
      case 'match_found':
        return AppColors.accentOrange;
      case 'report_nearby':
        return AppColors.primary;
      case 'pet_safe':
        return Colors.green;
      case 'warning':
        return Colors.amber[800]!;
      case 'suspension':
        return Colors.redAccent;
      case 'status_update':
        return Colors.blueAccent;
      case 'match_confirmed':
        return Colors.teal;
      case 'report_update':
        return Colors.indigoAccent;
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

            // Message + time + view post indicator
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
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        _timeAgo(notification.createdAt),
                        style: const TextStyle(fontSize: 12, color: AppColors.text3),
                      ),
                      if (notification.isPostRelated) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.visibility_outlined,
                                  size: 11.5, color: color),
                              const SizedBox(width: 3.5),
                              Text(
                                'View Post',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Action Chevron for post-related items
            if (notification.isPostRelated)
              Padding(
                padding: const EdgeInsets.only(left: 6, top: 10),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: isUnread ? AppColors.darkCharcoal : AppColors.text3,
                ),
              ),

            // Unread dot
            if (isUnread)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 6),
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
