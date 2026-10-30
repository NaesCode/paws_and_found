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
}