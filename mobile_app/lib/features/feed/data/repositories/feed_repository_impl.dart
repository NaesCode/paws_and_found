// ignore_for_file: use_null_aware_elements
import 'dart:async' show unawaited;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:paws_and_found/core/network/orchestrator_client.dart';
import 'package:paws_and_found/features/map/data/models/map_report_model.dart';
import 'package:paws_and_found/features/feed/data/models/comment_model.dart';
import 'package:paws_and_found/features/feed/data/models/feed_post_model.dart';
import 'package:paws_and_found/features/feed/domain/repositories/feed_repository.dart';

//fetching data both personal and general with each filters na

class FeedRepositoryImpl implements FeedRepository {
  final SupabaseClient _supabase;
  final OrchestratorClient _orchestratorClient;

  FeedRepositoryImpl({
    SupabaseClient? supabaseClient,
    OrchestratorClient? orchestratorClient,
  })  : _supabase = supabaseClient ?? Supabase.instance.client,
        _orchestratorClient = orchestratorClient ?? OrchestratorClient();

  @override
  Future<List<FeedPost>> getPersonalReports(String userId, {String? filterStatus}) async {
    try {
      var query = _supabase.from('reports').select('''
        id,
        reporter_id,
        pet_id,
        animal_type,
        animal_name,
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
        animal_name,
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
        animal_name,
        analysis_status, 
        moderation_status,
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

  @override
  Future<List<FeedPost>> getLinkedSightings(String reportId) async {
    try {
      final List<Map<String, dynamic>> response = await _supabase
          .from('reports')
          .select('''
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
            pets(name),
            animal_name
          ''')
          .eq('linked_report_id', reportId)
          .order('created_at', ascending: false);

      if (response.isNotEmpty) {
        return response.map((json) => FeedPost.fromJson(json)).toList();
      }
    } catch (_) {}

    // Fallback: Check comments containing embedded sighting links
    try {
      final comments = await getComments(reportId);
      final sightingReportIds = comments
          .map((c) => c.linkedReportId)
          .whereType<String>()
          .toSet();

      if (sightingReportIds.isEmpty) return [];

      final List<FeedPost> fallbackSightings = [];
      for (final sId in sightingReportIds) {
        final p = await getReportById(sId);
        if (p != null) fallbackSightings.add(p);
      }
      return fallbackSightings;
    } catch (_) {
      return [];
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
    } finally {
      // Purge from in-memory map cache so the marker immediately vanishes from the map canvas
      MapReportModel.removeReport(reportId);
    }
  }

  @override
  Future<String> uploadReportPhoto(
    Uint8List bytes, {
    String extension = 'jpg',
  }) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) throw Exception('User is not authenticated');
    const uuid = Uuid();
    final path = '$uid/${uuid.v4()}.$extension';

    await _supabase.storage.from('animal-photos').uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(
        contentType: 'image/$extension',
        upsert: false,
      ),
    );
    return _supabase.storage.from('animal-photos').getPublicUrl(path);
  }

  @override
  Future<void> updateReport(
    String reportId, {
    String? description,
    String? locationName,
    String? status,
    String? animalType,
    String? photoUrl,
    String? petId,
    String? petName,
    double? lat,
    double? lng,
    String? specie,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (description != null) updates['description'] = description.trim();
      if (locationName != null) updates['location_name'] = locationName.trim();
      if (status != null) updates['status'] = status.toLowerCase();
      if (animalType != null) updates['animal_type'] = animalType.trim();
      
      if (petId == null && specie != null && specie.isNotEmpty) {
        updates['animal_type'] = specie.trim();
      }

      if (petId == null && petName != null && petName.trim().isNotEmpty) {
        updates['animal_name'] = petName.trim();
      }

      if (lat != null && lng != null) {
        updates['location'] = 'POINT($lng $lat)';
      }

      // delete-before-upload logic ni siya
      if (photoUrl != null && photoUrl.isNotEmpty) {
        updates['photo_url'] = photoUrl;

        // Reset analysis_status so the AI orchestrator re-extracts embeddings for the new photo.
        // Without this, matching.py would continue using stale feature vectors from the old image.
        updates['analysis_status'] = 'pending';

        // Fetch the current report from the database to see if a photo already exists
        final currentReport = await getReportById(reportId);
        
        if (currentReport != null && currentReport.imageUrl.isNotEmpty) {
          final oldUrl = currentReport.imageUrl;

          // Only delete if the image actually changed
          if (oldUrl != photoUrl) {
            try {
              // Extract the relative storage path out of the full Public URL
              final String storageUrlMatchToken = '/storage/v1/object/public/animal-photos/';
              
              if (oldUrl.contains(storageUrlMatchToken)) {
                final relativePath = oldUrl.split(storageUrlMatchToken).last;
                
                // Delete the old photo from the bucket immediately
                await _supabase.storage
                  .from('animal-photos')
                  .remove([relativePath]);
              }
            } catch (storageError) {
              // Log the error but don't crash the application; let the DB update proceed
              debugPrint('[FeedRepositoryImpl] Failed to delete orphaned storage file: $storageError');
            }
          }
        }
      }

      if (updates.isNotEmpty) {
        await _supabase.from('reports').update(updates).eq('id', reportId);

        // If the photo was changed, trigger an asynchronous re-analysis on the orchestrator
        if (photoUrl != null && photoUrl.isNotEmpty) {
          unawaited(_requestReportAnalysis(reportId));
        }
      }
    } catch (e) {
      throw Exception('Failed to update report: $e');
    }
  }

  /// Requests the AI micro-orchestrator to re-extract embeddings and re-run forward matching
  Future<void> _requestReportAnalysis(String reportId) async {
    try {
      await _orchestratorClient.post('/api/reports/$reportId/analyze/');
      debugPrint('[FeedRepositoryImpl] AI re-analysis requested for report: $reportId');
    } catch (e) {
      debugPrint('[FeedRepositoryImpl] AI re-analysis dispatch deferred (orchestrator offline): $e');
    }
  }
}

