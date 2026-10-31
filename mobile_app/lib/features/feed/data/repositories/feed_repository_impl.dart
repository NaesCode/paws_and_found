import 'package:supabase_flutter/supabase_flutter.dart';
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
        moderation_status,
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
        moderation_status, 
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
  Future<void> deleteReport(String reportId, {String? reason, String? details}) async {
    try {
      await _supabase.rpc('delete_report', params: {
        'p_report_id': reportId,
        'p_reason': reason ?? 'Mistake / False Alarm',
        if (details != null && details.trim().isNotEmpty) 'p_details': details.trim(),
      });
    } catch (_) {
      // Direct deletion fallback if RPC is not yet migrated in database
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId != null) {
        final row = await _supabase.from('reports').select('pet_id').eq('id', reportId).maybeSingle();
        if (row != null && row['pet_id'] != null) {
          await _supabase.from('pets').update({
            'status': 'safe',
            'missing_since': null,
            'last_known_location': null,
          }).eq('id', row['pet_id']).eq('owner_id', currentUserId);
        }
        await _supabase.from('matches').delete().eq('report_id', reportId);
        await _supabase.from('reports').delete().eq('id', reportId).eq('reporter_id', currentUserId);
      }
    }
  }
}
