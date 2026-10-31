import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../models/app_notification_model.dart';

/// Fetches and mutates notifications directly via Supabase PostgREST and Realtime.
///
/// RLS on the `notifications` table ensures a user can only ever see
/// and update rows where `user_id = auth.uid()`.
class NotificationRepositoryImpl implements NotificationRepository {
  final SupabaseClient _supabase;

  NotificationRepositoryImpl({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String get _uid {
    final id = _supabase.auth.currentUser?.id;
    if (id == null) throw Exception('User is not authenticated');
    return id;
  }

  // ---------------------------------------------------------------------------
  // Read (One-off & Realtime Streams)
  // ---------------------------------------------------------------------------

  @override
  Future<List<AppNotification>> getNotifications() async {
    final response = await _supabase
        .from('notifications')
        .select()
        .eq('user_id', _uid)
        .order('created_at', ascending: false)
        .limit(50);

    return (response as List<dynamic>)
        .map((row) =>
            AppNotificationModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Stream<List<AppNotification>> streamNotifications() {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return Stream.value(<AppNotification>[]);
      }

      return _supabase
          .from('notifications')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .map((rows) => rows
              .map((row) => AppNotificationModel.fromJson(row))
              .toList());
    } catch (_) {
      return Stream.value(<AppNotification>[]);
    }
  }

  @override
  Stream<int> streamUnreadCount() {
    return streamNotifications()
        .map((list) => list.where((n) => !n.isRead).length);
  }

  @override
  Future<int> getUnreadCount() async {
    // PostgREST count: pass CountOption.exact to get the row count in the header.
    final response = await _supabase
        .from('notifications')
        .select()
        .eq('user_id', _uid)
        .eq('is_read', false)
        .count(CountOption.exact);

    return response.count;
  }

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  @override
  Future<void> markRead(String notificationId) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId)
        .eq('user_id', _uid); // double-check ownership (RLS also enforces this)
  }

  @override
  Future<void> markAllRead() async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', _uid)
        .eq('is_read', false);
  }
}
