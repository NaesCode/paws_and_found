import 'package:supabase_flutter/supabase_flutter.dart';

/// Abstract contract for feed remote operations.
abstract class FeedRemoteDataSource {
  /// Fetches community feed reports with unpacked coordinates (lat/lng).
  Future<List<Map<String, dynamic>>> getFeedReports({int limit = 50, int offset = 0});

  /// Fetches reports submitted by a specific user.
  Future<List<Map<String, dynamic>>> getUserFeedReports(String userId, {int limit = 50});
}

/// Concrete implementation that queries the `feed_reports` database view in Supabase.
class FeedRemoteDataSourceImpl implements FeedRemoteDataSource {
  final SupabaseClient? _supabase;

  FeedRemoteDataSourceImpl({SupabaseClient? client})
      : _supabase = client ?? _safeGetSupabaseClient();

  static SupabaseClient? _safeGetSupabaseClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getFeedReports({
    int limit = 50,
    int offset = 0,
  }) async {
    final client = _supabase;
    if (client == null) return [];

    try {
      final response = await client
          .from('feed_reports')
          .select()
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getUserFeedReports(
    String userId, {
    int limit = 50,
  }) async {
    final client = _supabase;
    if (client == null) return [];

    try {
      final response = await client
          .from('feed_reports')
          .select()
          .eq('reporter_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return [];
    }
  }
}
