import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/location_constants.dart';
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
      : _supabase = client ?? _safeGetClient();

  static SupabaseClient _safeGetClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      // For disconnected testing environments
      return SupabaseClient('http://localhost:54321', 'dummy-key');
    }
  }

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
        .eq('user_id', _uid);
  }

  @override
  Future<void> markAllRead() async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', _uid)
        .eq('is_read', false);
  }

  // ---------------------------------------------------------------------------
  // Post Details Resolution (Smart Matching by ID, Match, and Pet Name)
  // ---------------------------------------------------------------------------

  @override
  Future<Map<String, dynamic>?> getPostDetailsForNotification(
      AppNotification notification) async {
    // 0. If notification is not post-related (e.g. withdrawal, removal, system message), no active post exists
    if (!notification.isPostRelated) {
      return null;
    }

    String? reportId = notification.relatedReportId;

    // 1. If relatedMatchId is set and reportId is null, resolve from matches
    if (reportId == null && notification.relatedMatchId != null) {
      try {
        final matchRow = await _supabase
            .from('matches')
            .select('report_id')
            .eq('id', notification.relatedMatchId!)
            .maybeSingle();
        if (matchRow != null && matchRow['report_id'] != null) {
          reportId = matchRow['report_id'].toString();
        }
      } catch (_) {}
    }

    // 2. Fetch directly from feed_reports view by reportId
    if (reportId != null && reportId.isNotEmpty) {
      try {
        final row = await _supabase
            .from('feed_reports')
            .select()
            .eq('id', reportId)
            .maybeSingle();
        if (row != null) {
          return await _enrichFeedReportRow(row);
        }
      } catch (_) {}

      try {
        final row = await _supabase
            .from('reports')
            .select('*, profiles:reporter_id(name), pets:pet_id(name, species, breed, photo_urls)')
            .eq('id', reportId)
            .maybeSingle();
        if (row != null) {
          final petMap = row['pets'] as Map<String, dynamic>?;
          return await _mapReportWithPet(row, petMap);
        }
      } catch (_) {}

      // If a specific reportId was referenced but not found, the report was deleted/withdrawn
      return null;
    }

    // 3. Try to query by extracted post ID (e.g. short ID #9B2A or UUID)
    final shortId = notification.extractedPostId;
    if (shortId != null && shortId.isNotEmpty) {
      try {
        final row = await _supabase
            .from('feed_reports')
            .select()
            .ilike('id', '$shortId%')
            .limit(1)
            .maybeSingle();
        if (row != null) {
          return await _enrichFeedReportRow(row);
        }
      } catch (_) {}
    }

    // 4. Smart Pet Name Matching (e.g. "Mingay", "Max", "Bruno")
    final petName = _extractPetName(notification.message);
    if (petName != null && petName.isNotEmpty) {
      // 4A. Query feed_reports view by pet_name
      try {
        final row = await _supabase
            .from('feed_reports')
            .select()
            .ilike('pet_name', '%$petName%')
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        if (row != null) {
          return await _enrichFeedReportRow(row);
        }
      } catch (_) {}

      // 4B. Query reports joined with pets
      try {
        final reports = await _supabase
            .from('reports')
            .select('*, profiles:reporter_id(name), pets:pet_id(name, species, breed, photo_urls)')
            .order('created_at', ascending: false)
            .limit(40);

        for (final r in reports) {
          final petMap = r['pets'] as Map<String, dynamic>?;
          final pName = petMap?['name']?.toString() ?? '';
          if (pName.toLowerCase().contains(petName.toLowerCase())) {
            return await _mapReportWithPet(r, petMap);
          }
        }
      } catch (_) {}

      // 4C. Query pets table directly by name
      try {
        final petRow = await _supabase
            .from('pets')
            .select('*, profiles:owner_id(name)')
            .ilike('name', '%$petName%')
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (petRow != null) {
          // Check if there is an active feed_report for this pet
          try {
            final rep = await _supabase
                .from('feed_reports')
                .select()
                .eq('pet_id', petRow['id'])
                .order('created_at', ascending: false)
                .limit(1)
                .maybeSingle();
            if (rep != null) {
              final mapped = await _enrichFeedReportRow(rep);
              if ((mapped['photoUrl'] as String? ?? '').isEmpty) {
                final photos = petRow['photo_urls'] as List<dynamic>?;
                if (photos != null && photos.isNotEmpty) {
                  mapped['photoUrl'] = photos.first.toString();
                }
              }
              return mapped;
            }
          } catch (_) {}

          return _mapPetToPostDetails(petRow);
        }
      } catch (_) {}
    }

    // 5. Fallback synthesis for demo / offline test environments with named pets
    if (petName != null && petName.isNotEmpty) {
      return _synthesizePostDetails(notification);
    }

    return null;
  }

  /// Extracts pet name from typical notification message templates.
  String? _extractPetName(String message) {
    // 1. "Urgent Alert: Mingay (Cat) was reported missing..."
    var match = RegExp(r'Urgent Alert:\s*([^(]+?)\s*\(', caseSensitive: false)
        .firstMatch(message);
    if (match != null) return match.group(1)?.trim();

    // 2. "Search broadcast active: Mingay has been reported missing..."
    match = RegExp(r'Search broadcast active:\s*([^\s]+)\s+has been',
            caseSensitive: false)
        .firstMatch(message);
    if (match != null) return match.group(1)?.trim();

    // 3. "resembling Mingay was reported..." or "resembling Mingay ("
    match = RegExp(r'resembling\s+([^\s,\.!]+)', caseSensitive: false)
        .firstMatch(message);
    if (match != null) return match.group(1)?.trim();

    // 4. "looks like Mingay was reported..."
    match = RegExp(r'looks like\s+([^\s,\.!]+)', caseSensitive: false)
        .firstMatch(message);
    if (match != null) return match.group(1)?.trim();

    // 5. "missing pet Mingay..."
    match = RegExp(r'missing pet\s+([^\s,\.!]+)', caseSensitive: false)
        .firstMatch(message);
    if (match != null) return match.group(1)?.trim();

    // 6. "Wonderful news! Mingay is safely home..."
    match = RegExp(r'Wonderful news!\s*([^\s]+)\s+is safely',
            caseSensitive: false)
        .firstMatch(message);
    if (match != null) return match.group(1)?.trim();

    // 7. "Great news! Mingay has been safely reunited..."
    match = RegExp(r'Great news!\s*([^\s]+)\s+has been',
            caseSensitive: false)
        .firstMatch(message);
    if (match != null) return match.group(1)?.trim();

    // 8. "Pet Profile Removed: Mingay has been removed..."
    match = RegExp(r'Pet Profile Removed:\s*([^\s]+)\s+has been',
            caseSensitive: false)
        .firstMatch(message);
    if (match != null) return match.group(1)?.trim();

    return null;
  }

  Future<Map<String, dynamic>> _enrichFeedReportRow(
      Map<String, dynamic> row) async {
    final petId = row['pet_id']?.toString();
    String photoUrl = row['photo_url']?.toString() ?? '';

    // If report photo_url is empty, fetch the pet's photo from pets table
    if (photoUrl.isEmpty && petId != null && petId.isNotEmpty) {
      try {
        final petData = await _supabase
            .from('pets')
            .select('photo_urls')
            .eq('id', petId)
            .maybeSingle();
        final photos = petData?['photo_urls'] as List<dynamic>?;
        if (photos != null && photos.isNotEmpty) {
          photoUrl = photos.first.toString();
        }
      } catch (_) {}
    }

    final lat = (row['latitude'] as num?)?.toDouble();
    final lng = (row['longitude'] as num?)?.toDouble();

    return {
      'id': row['id']?.toString() ?? '',
      'petId': petId,
      'reporterId': row['reporter_id']?.toString() ?? '',
      'title': (row['pet_name'] != null && row['pet_name'] != 'Unnamed Pet')
          ? row['pet_name'].toString()
          : '${row['animal_type'] ?? 'Animal'} Sighting',
      'animalType': row['animal_type']?.toString() ?? 'Animal',
      'status': row['status']?.toString() ?? 'missing',
      'description': row['description']?.toString() ?? '',
      'photoUrl': photoUrl,
      'locationName': 'Cebu City, Philippines',
      'latitude': lat ?? LocationConstants.defaultLatitude,
      'longitude': lng ?? LocationConstants.defaultLongitude,
      'reporterName': row['reporter_name']?.toString() ?? 'Community Member',
      'createdAt': row['created_at'] != null
          ? DateTime.tryParse(row['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      'moderationStatus': row['moderation_status']?.toString() ?? 'approved',
      'moderationNotes': row['moderation_notes']?.toString(),
    };
  }

  Future<Map<String, dynamic>> _mapReportWithPet(
      Map<String, dynamic> report, Map<String, dynamic>? petMap) async {
    final petId = report['pet_id']?.toString() ?? petMap?['id']?.toString();
    String? photoUrl = report['photo_url']?.toString();

    if ((photoUrl == null || photoUrl.isEmpty) && petMap != null) {
      final petPhotos = petMap['photo_urls'] as List<dynamic>?;
      if (petPhotos != null && petPhotos.isNotEmpty) {
        photoUrl = petPhotos.first.toString();
      }
    }

    final profileMap = report['profiles'] as Map<String, dynamic>?;

    final animalType = report['animal_type']?.toString() ??
        petMap?['species']?.toString() ??
        'Animal';
    final petName = petMap?['name']?.toString();
    final title = (petName != null && petName.isNotEmpty)
        ? petName
        : '$animalType Sighting';

    final finalPhoto = (photoUrl != null && photoUrl.isNotEmpty)
        ? photoUrl
        : (petMap?['photo_urls'] is List &&
                (petMap!['photo_urls'] as List).isNotEmpty
            ? petMap['photo_urls'][0].toString()
            : '');

    double? lat;
    double? lng;
    final reportId = report['id']?.toString();
    if (reportId != null) {
      try {
        final fRow = await _supabase
            .from('feed_reports')
            .select('latitude, longitude')
            .eq('id', reportId)
            .maybeSingle();
        if (fRow != null) {
          lat = (fRow['latitude'] as num?)?.toDouble();
          lng = (fRow['longitude'] as num?)?.toDouble();
        }
      } catch (_) {}
    }

    return {
      'id': report['id']?.toString() ?? '',
      'petId': petId,
      'reporterId': report['reporter_id']?.toString() ?? '',
      'title': title,
      'animalType': animalType,
      'status': report['status']?.toString() ?? 'missing',
      'description': (report['description'] != null &&
              report['description'].toString().isNotEmpty)
          ? report['description'].toString()
          : (petMap?['description']?.toString() ?? ''),
      'photoUrl': finalPhoto,
      'locationName':
          report['location_name']?.toString() ?? 'Cebu Community Area',
      'latitude': lat ?? LocationConstants.defaultLatitude,
      'longitude': lng ?? LocationConstants.defaultLongitude,
      'reporterName': profileMap?['name']?.toString() ?? 'Community Member',
      'createdAt': report['created_at'] != null
          ? DateTime.tryParse(report['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      'moderationStatus':
          report['moderation_status']?.toString() ?? 'approved',
      'moderationNotes': report['moderation_notes']?.toString(),
    };
  }

  Map<String, dynamic> _mapPetToPostDetails(Map<String, dynamic> petRow) {
    final photoUrls = petRow['photo_urls'] as List<dynamic>?;
    final petPhoto = (photoUrls != null && photoUrls.isNotEmpty)
        ? photoUrls.first.toString()
        : '';

    final profileMap = petRow['profiles'] as Map<String, dynamic>?;

    return {
      'id': petRow['id']?.toString() ?? '',
      'petId': petRow['id']?.toString(),
      'reporterId': petRow['owner_id']?.toString() ?? '',
      'title': petRow['name']?.toString() ?? 'Pet Sighting',
      'animalType': petRow['species']?.toString() ?? 'Animal',
      'status': petRow['status']?.toString() ?? 'missing',
      'description': petRow['description']?.toString() ??
          'Reported missing in your community. Please keep an eye out!',
      'photoUrl': petPhoto,
      'locationName': 'Cebu City, Philippines',
      'latitude': LocationConstants.defaultLatitude,
      'longitude': LocationConstants.defaultLongitude,
      'reporterName': profileMap?['name']?.toString() ?? 'Pet Owner',
      'createdAt': petRow['created_at'] != null
          ? DateTime.tryParse(petRow['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      'moderationStatus': 'approved',
      'moderationNotes': null,
    };
  }

  Map<String, dynamic> _synthesizePostDetails(AppNotification notification) {
    final petName = _extractPetName(notification.message);
    final title = petName ?? 'Community Animal Sighting';
    String animalType = 'Dog';
    String status = 'missing';

    final msgLower = notification.message.toLowerCase();
    if (msgLower.contains('cat') || msgLower.contains('feline')) animalType = 'Cat';
    if (msgLower.contains('dog') || msgLower.contains('canine')) animalType = 'Dog';
    if (msgLower.contains('found') || msgLower.contains('safe')) status = 'found';
    if (msgLower.contains('stray') || msgLower.contains('spotted')) status = 'stray';
    if (msgLower.contains('missing')) status = 'missing';

    final id = notification.extractedPostId != null
        ? '#${notification.extractedPostId}'
        : (petName != null
            ? '#$petName'
            : '#${notification.id.substring(0, 4.clamp(0, notification.id.length)).toUpperCase()}');

    return {
      'id': id,
      'title': title,
      'animalType': animalType,
      'status': status,
      'description': notification.message,
      'photoUrl': '',
      'locationName': 'Cebu City, Philippines',
      'latitude': LocationConstants.defaultLatitude,
      'longitude': LocationConstants.defaultLongitude,
      'reporterName': 'Community Member',
      'createdAt': notification.createdAt,
      'moderationStatus': notification.type == 'warning' ? 'flagged' : 'approved',
      'moderationNotes': notification.type == 'warning'
          ? 'An administrator requested revisions for this post.'
          : null,
    };
  }
}
