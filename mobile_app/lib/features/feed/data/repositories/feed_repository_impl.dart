// ignore_for_file: use_null_aware_elements
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:paws_and_found/features/feed/data/models/comment_model.dart';
import 'package:paws_and_found/features/feed/data/models/feed_post_model.dart';
import 'package:paws_and_found/features/feed/domain/repositories/feed_repository.dart';

//fetching data both personal and general with each filters na

class FeedRepositoryImpl implements FeedRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<List<FeedPost>> getPersonalReports(String userId, {String? filterStatus}) async {
    try {
      var query = _supabase.from('reports').select('''
        id,
        reporter_id,
        pet_id,
        animal_type,
        description,
        photo_url,
        location_name,
        status,
        analysis_status,
        created_at,
        profiles(name, profile_photo_url),
        pets(name)
      ''').eq('reporter_id', userId);

      if (filterStatus != null && filterStatus.isNotEmpty) {
        query = query.ilike('status', filterStatus); 
      }

      final List<Map<String, dynamic>> response = await query.order('created_at', ascending: false);

      return response.map((json) => FeedPost.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch personal reports: $e');
    }
  }

  @override 
  Future<List<FeedPost>> getGeneralReports(String userId, {String? filterStatus, bool sortOldest = false}) async {
    try {
      var query = _supabase.from('reports').select('''
        id, 
        reporter_id, 
        pet_id, 
        animal_type, 
        description, 
        photo_url, 
        location_name, 
        status, 
        analysis_status, 
        created_at,
        profiles(name, profile_photo_url),
        pets(name)
      ''').neq('reporter_id', userId);

      if (filterStatus != null && filterStatus.isNotEmpty) {
        query = query.ilike('status', filterStatus);
      }

      final List<Map<String, dynamic>> response = await query.order(
        'created_at', 
        ascending: sortOldest,
      );

      return response.map((json) => FeedPost.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch general reports: $e');
    }
  }

  @override
  Future<FeedPost?> getReportById(String reportId) async {
    try {
      final response = await _supabase.from('reports').select('''
        id, 
        reporter_id, 
        pet_id, 
        animal_type, 
        description, 
        photo_url, 
        location_name, 
        status, 
        analysis_status, 
        created_at,
        profiles(name, profile_photo_url),
        pets(name)
      ''').eq('id', reportId).maybeSingle();

      if (response == null) return null;
      return FeedPost.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<FeedComment>> getComments(String reportId) async {
    try {
      final List<dynamic> rawComments = await _supabase
          .from('comments')
          .select()
          .eq('post_id', reportId)
          .order('created_at', ascending: true);

      if (rawComments.isEmpty) return [];

      final typedComments = rawComments.cast<Map<String, dynamic>>();

      // Extract unique user IDs to fetch their profiles in a single batch
      final userIds = typedComments
          .map((c) => c['user_id'] as String?)
          .whereType<String>()
          .toSet()
          .toList();

      final Map<String, Map<String, dynamic>> profileMap = {};
      if (userIds.isNotEmpty) {
        final List<dynamic> profiles = await _supabase
            .from('profiles')
            .select('id, name, profile_photo_url')
            .inFilter('id', userIds);

        for (final p in profiles.cast<Map<String, dynamic>>()) {
          final id = p['id'] as String?;
          if (id != null) profileMap[id] = p;
        }
      }

      return typedComments.map((c) {
        final uid = c['user_id'] as String?;
        return FeedComment.fromJson(c, profile: uid != null ? profileMap[uid] : null);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<FeedComment> addComment(String reportId, String content, {String? parentId}) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      throw Exception('Must be logged in to comment');
    }

    final inserted = await _supabase.from('comments').insert({
      'post_id': reportId,
      'user_id': currentUserId,
      'content': content.trim(),
      if (parentId != null) 'parent_id': parentId,
    }).select().single();

    final profile = await _supabase
        .from('profiles')
        .select('name, profile_photo_url')
        .eq('id', currentUserId)
        .maybeSingle();

    return FeedComment.fromJson(inserted, profile: profile);
  }
}
