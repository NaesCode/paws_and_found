import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/admin_post_item.dart';
import '../models/admin_user_item.dart';

abstract class AdminRemoteDataSource {
  Future<List<AdminUserItem>> fetchUsers();
  Future<List<AdminPostItem>> fetchPosts();
  Future<void> deletePost(
    String postId, {
    String? reason,
    bool notifyUser = false,
  });
  Future<void> updateUserStatus({
    required String userId,
    required String status,
    String? message,
  });
  Future<void> warnUserForPost({
    required String postId,
    required String userId,
    required String reason,
    String? message,
  });
}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final SupabaseClient _supabase;

  AdminRemoteDataSourceImpl({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  @override
  Future<List<AdminUserItem>> fetchUsers() async {
    final response = await _supabase
        .from('profiles')
        .select('*')
        .order('created_at', ascending: false);

    final List<dynamic> data = response as List<dynamic>;
    return data
        .map((item) => AdminUserItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<AdminPostItem>> fetchPosts() async {
    try {
      final response = await _supabase
          .from('reports')
          .select(
              '*, profiles:reporter_id(name, email), pets:pet_id(name, species, breed)')
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((item) => AdminPostItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Fallback in case of foreign key alias naming variance
      final fallbackResponse = await _supabase
          .from('reports')
          .select('*')
          .order('created_at', ascending: false);

      final List<dynamic> data = fallbackResponse as List<dynamic>;
      return data
          .map((item) => AdminPostItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }
  }

  @override
  Future<void> deletePost(
    String postId, {
    String? reason,
    bool notifyUser = false,
  }) async {
    try {
      // 1. Try atomic admin delete RPC
      await _supabase.rpc('admin_delete_post', params: {
        'p_post_id': postId,
        if (reason != null && reason.isNotEmpty) 'p_reason': reason,
        'p_notify_user': notifyUser,
      });
    } catch (_) {
      // 2. Direct fallback
      await _supabase.from('reports').delete().eq('id', postId);
    }
  }

  @override
  Future<void> updateUserStatus({
    required String userId,
    required String status,
    String? message,
  }) async {
    try {
      // 1. Try atomic RPC (handles status update + notification creation via security definer)
      await _supabase.rpc('admin_update_user_status', params: {
        'p_user_id': userId,
        'p_status': status,
        if (message != null && message.isNotEmpty) 'p_message': message,
      });
    } catch (_) {
      // 2. Direct fallback in case RPC is not yet registered in Supabase
      try {
        await _supabase
            .from('profiles')
            .update({'status': status})
            .eq('id', userId);
      } catch (_) {}

      try {
        final notifType = status.toLowerCase() == 'warning'
            ? 'warning'
            : (status.toLowerCase().contains('suspend')
                ? 'suspension'
                : 'status_update');

        final defaultMessage = status.toLowerCase() == 'warning'
            ? 'Your account has received an administrative warning regarding community guidelines.'
            : (status.toLowerCase().contains('suspend')
                ? 'Your account has been suspended by administration. If you have questions, please contact support.'
                : 'Your account status is set to Active. You have full access to community features.');

        final notifMsg = (message != null && message.isNotEmpty)
            ? message
            : defaultMessage;

        await _supabase.from('notifications').insert({
          'user_id': userId,
          'type': notifType,
          'message': notifMsg,
        });
      } catch (_) {}
    }
  }

  @override
  Future<void> warnUserForPost({
    required String postId,
    required String userId,
    required String reason,
    String? message,
  }) async {
    try {
      // 1. Try atomic admin warning RPC
      final params = <String, dynamic>{
        'p_post_id': postId,
        'p_reason': reason,
      };
      if (userId.isNotEmpty) {
        params['p_user_id'] = userId;
      }
      if (message != null && message.isNotEmpty) {
        params['p_message'] = message;
      }
      await _supabase.rpc('admin_warn_user_for_post', params: params);
    } catch (_) {
      // 2. Fallback: resolve reporter_id if not directly provided
      String targetUserId = userId;
      if (targetUserId.isEmpty) {
        try {
          final res = await _supabase
              .from('reports')
              .select('reporter_id')
              .eq('id', postId)
              .maybeSingle();
          if (res != null && res['reporter_id'] != null) {
            targetUserId = res['reporter_id'].toString();
          }
        } catch (_) {}
      }

      if (targetUserId.isNotEmpty) {
        try {
          await _supabase
              .from('profiles')
              .update({'status': 'Warning'})
              .eq('id', targetUserId);
        } catch (_) {}

        try {
          final notifMessage = (message != null && message.isNotEmpty)
              ? message
              : 'Your post has received an administrative warning for: $reason. Please review our community guidelines.';

          await _supabase.from('notifications').insert({
            'user_id': targetUserId,
            'type': 'warning',
            'message': notifMessage,
          });
        } catch (_) {}
      }
    }
  }
}
