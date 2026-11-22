import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';

import '../../../../shared/atoms/app_logo.dart';
import '../../../../shared/molecules/paw_loading.dart';
import '../../../../shared/organisms/custom_app_bar.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../widgets/post_details_bottom_sheet.dart';

// ---------------------------------------------------------------------------
// Filter definitions
// ---------------------------------------------------------------------------

enum _NotifFilter {
  all,
  unread,
  matches,
  nearby,
  updates,
  system,
}

extension _NotifFilterExt on _NotifFilter {
  String get label {
    switch (this) {
      case _NotifFilter.all:
        return 'All';
      case _NotifFilter.unread:
        return 'Unread';
      case _NotifFilter.matches:
        return 'Matches';
      case _NotifFilter.nearby:
        return 'Nearby';
      case _NotifFilter.updates:
        return 'Updates';
      case _NotifFilter.system:
        return 'System';
    }
  }

  IconData get icon {
    switch (this) {
      case _NotifFilter.all:
        return Icons.notifications_rounded;
      case _NotifFilter.unread:
        return Icons.mark_chat_unread_rounded;
      case _NotifFilter.matches:
        return Icons.favorite_rounded;
      case _NotifFilter.nearby:
        return Icons.location_on_rounded;
      case _NotifFilter.updates:
        return Icons.campaign_rounded;
      case _NotifFilter.system:
        return Icons.info_rounded;
    }
  }

  bool matches(AppNotification n) {
    switch (this) {
      case _NotifFilter.all:
        return true;
      case _NotifFilter.unread:
        return !n.isRead;
      case _NotifFilter.matches:
        return n.type == 'match_found' || n.type == 'match_confirmed';
      case _NotifFilter.nearby:
        return n.type == 'report_nearby';
      case _NotifFilter.updates:
        return n.type == 'report_update' ||
            n.type == 'pet_safe' ||
            n.type == 'status_update' ||
            n.type == 'verification_request';
      case _NotifFilter.system:
        return n.type == 'welcome' ||
            n.type == 'warning' ||
            n.type == 'suspension';
    }
  }
}

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

/// Notification inbox with:
/// - Filter chip bar (All / Unread / Matches / Nearby / Updates / System)
/// - Swipe-to-delete on individual rows (with undo snackbar)
/// - Long-press → "Clear all" confirmation dialog
/// - "Mark all read" action in app bar
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

  _NotifFilter _activeFilter = _NotifFilter.all;

  /// IDs of notifications currently being deleted (undo window still open OR
  /// DB call in-flight). Items in this set are excluded from the displayed list
  /// so that Supabase Realtime stream updates cannot restore them visually.
  final Set<String> _pendingDeleteIds = {};

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

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

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Data
  // ---------------------------------------------------------------------------

  void _subscribe() {
    try {
      _subscription = _repo.streamNotifications().listen(
        (items) {
          if (mounted) {
            setState(() {
              // Keep items that are NOT in the pending-delete set so that
              // Realtime stream pushes cannot restore a notification while
              // an undo snackbar is open or a DB delete is in flight.
              _notifications = items
                  .where((n) => !_pendingDeleteIds.contains(n.id))
                  .toList();
              _isLoading = false;
              _error = null;
            });
          }
        },
        onError: (_) {},
      );
    } catch (_) {}
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

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

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
    await _markRead(n);
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

  /// Swipe-delete:
  /// 1. Marks ID as "pending delete" so the stream can't restore it visually.
  /// 2. Removes from local list immediately (optimistic UI).
  /// 3. Shows an UNDO snackbar for 4 seconds.
  /// 4. If UNDO is tapped within 4 seconds, restoration is instant and no DB delete occurs.
  /// 5. After the 4-second window expires, the snackbar disappears and the DB deletion executes.
  Future<void> _deleteNotification(AppNotification n) async {
    if (_pendingDeleteIds.contains(n.id)) return;

    final index = _notifications.indexOf(n);
    setState(() {
      _pendingDeleteIds.add(n.id);
      _notifications.remove(n);
    });

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    final completer = Completer<bool>();

    // Show the undo snackbar for 4 seconds
    final controller = messenger.showSnackBar(
      SnackBar(
        content: const Text('Notification removed'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: AppColors.accentOrange,
          onPressed: () {
            if (!completer.isCompleted) completer.complete(true);
          },
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      ),
    );

    controller.closed.then((_) {
      if (!completer.isCompleted) completer.complete(false);
    });

    final undone = await completer.future;

    if (undone) {
      // User tapped UNDO within 4 seconds — restore immediately without touching DB
      if (mounted) {
        setState(() {
          _pendingDeleteIds.remove(n.id);
          final safeIdx = index.clamp(0, _notifications.length);
          _notifications.insert(safeIdx, n);
        });
      }
      return;
    }

    // 4-second window elapsed — now commit the deletion to the database
    try {
      await _repo.deleteNotification(n.id);
      if (mounted) {
        setState(() => _pendingDeleteIds.remove(n.id));
      }
    } catch (e) {
      // DB deletion failed (e.g. missing SQL privilege) — restore item and notify
      if (mounted) {
        setState(() {
          _pendingDeleteIds.remove(n.id);
          final safeIdx = index.clamp(0, _notifications.length);
          _notifications.insert(safeIdx, n);
        });
        messenger.showSnackBar(
          SnackBar(
            content: Text('Could not delete: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          ),
        );
      }
    }
  }

  Future<void> _confirmClearAll() async {
    final filtered = _filtered;
    if (filtered.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear notifications?'),
        content: Text(
          _activeFilter == _NotifFilter.all
              ? 'All ${filtered.length} notification${filtered.length == 1 ? '' : 's'} will be permanently deleted.'
              : '${filtered.length} ${_activeFilter.label.toLowerCase()} notification${filtered.length == 1 ? '' : 's'} will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    if (_activeFilter == _NotifFilter.all) {
      // Clear everything at once
      setState(() => _notifications.clear());
      try {
        await _repo.clearAllNotifications();
      } catch (_) {
        _load(); // restore on failure
      }
    } else {
      // Only delete the currently-visible filtered subset
      final toDelete = List<AppNotification>.from(filtered);
      setState(() => _notifications.removeWhere((n) => toDelete.contains(n)));
      for (final n in toDelete) {
        try {
          await _repo.deleteNotification(n.id);
        } catch (_) {}
      }
    }
  }

  AppNotification _asRead(AppNotification n) => AppNotification(
        id: n.id,
        userId: n.userId,
        type: n.type,
        message: n.message,
        relatedMatchId: n.relatedMatchId,
        relatedReportId: n.relatedReportId,
        isRead: true,
        createdAt: n.createdAt,
      );

  // ---------------------------------------------------------------------------
  // Derived state
  // ---------------------------------------------------------------------------

  List<AppNotification> get _filtered => _notifications
      .where((n) => !_pendingDeleteIds.contains(n.id))
      .where(_activeFilter.matches)
      .toList();

  int get _unreadTotal => _notifications
      .where((n) => !_pendingDeleteIds.contains(n.id) && !n.isRead)
      .length;

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLogo(size: 32),
            SizedBox(width: 10),
            Text('Notifications'),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          if (_unreadTotal > 0)
            TextButton.icon(
              onPressed: _markAllRead,
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              icon: const Icon(Icons.done_all_rounded, size: 16, color: Colors.white),
              label: const Text(
                'Mark all read',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: widget.showBottomNavPlaceholder
          ? CustomAppBar(
              currentIndex: 4,
              hasUnreadNotifications: _unreadTotal > 0,
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

    if (_error != null && _notifications.isEmpty) {
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

    return Column(
      children: [
        // ── Filter chip bar ──────────────────────────────────────────────
        _FilterChipBar(
          activeFilter: _activeFilter,
          notifications: _notifications,
          onFilterChanged: (f) => setState(() => _activeFilter = f),
        ),

        // ── List ─────────────────────────────────────────────────────────
        Expanded(child: _buildList()),
      ],
    );
  }

  Widget _buildList() {
    final visible = _filtered;

    if (visible.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _activeFilter == _NotifFilter.all
                  ? Icons.notifications_none_rounded
                  : _activeFilter.icon,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 16),
            Text(
              _activeFilter == _NotifFilter.all
                  ? 'All caught up!'
                  : 'No ${_activeFilter.label.toLowerCase()} notifications',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.darkCharcoal,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _activeFilter == _NotifFilter.all
                  ? 'You have no notifications yet.'
                  : 'Nothing here — try a different filter.',
              style: const TextStyle(color: AppColors.text3, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: visible.length + 1, // +1 for the clear-all footer
        itemBuilder: (context, index) {
          if (index == visible.length) {
            // Footer — "Clear all visible" button
            return _ClearAllFooter(
              count: visible.length,
              filterLabel: _activeFilter.label,
              onClear: _confirmClearAll,
            );
          }

          final n = visible[index];
          final isLast = index == visible.length - 1;

          return Column(
            children: [
              // Swipe-to-delete wrapper
              Dismissible(
                key: ValueKey(n.id),
                direction: DismissDirection.endToStart,
                // Red "Delete" background revealed on swipe
                background: Container(
                  alignment: Alignment.centerRight,
                  color: Colors.redAccent,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 26),
                      SizedBox(height: 4),
                      Text(
                        'Delete',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                confirmDismiss: (_) async => true,
                onDismissed: (_) => _deleteNotification(n),
                child: _NotificationTile(
                  notification: n,
                  onTap: () => _handleNotificationTap(n),
                ),
              ),
              if (!isLast)
                const Divider(height: 1, indent: 72, endIndent: 16),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter chip bar
// ---------------------------------------------------------------------------

class _FilterChipBar extends StatelessWidget {
  final _NotifFilter activeFilter;
  final List<AppNotification> notifications;
  final ValueChanged<_NotifFilter> onFilterChanged;

  const _FilterChipBar({
    required this.activeFilter,
    required this.notifications,
    required this.onFilterChanged,
  });

  int _countFor(_NotifFilter f) =>
      notifications.where(f.matches).length;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: _NotifFilter.values.map((f) {
            final count = _countFor(f);
            final isActive = f == activeFilter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onFilterChanged(f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        f.icon,
                        size: 14,
                        color: isActive ? Colors.white : AppColors.primary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        f.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isActive ? Colors.white : AppColors.primary,
                        ),
                      ),
                      if (count > 0) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.white.withValues(alpha: 0.25)
                                : AppColors.accentOrange,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isActive ? Colors.white : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Clear-all footer
// ---------------------------------------------------------------------------

class _ClearAllFooter extends StatelessWidget {
  final int count;
  final String filterLabel;
  final VoidCallback onClear;

  const _ClearAllFooter({
    required this.count,
    required this.filterLabel,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: OutlinedButton.icon(
        onPressed: onClear,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.redAccent,
          side: const BorderSide(color: Colors.redAccent, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 10),
          minimumSize: const Size(double.infinity, 0),
        ),
        icon: const Icon(Icons.delete_forever_rounded, size: 18),
        label: Text(
          'Clear all $filterLabel notifications ($count)',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Notification tile
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

            // Message + time + "View Post" pill
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
                              Icon(Icons.visibility_outlined, size: 11.5, color: color),
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
                      // Hint for swipe gesture
                      const Spacer(),
                      Icon(
                        Icons.swipe_left_alt_rounded,
                        size: 13,
                        color: AppColors.text3.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Chevron for post-related items
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
