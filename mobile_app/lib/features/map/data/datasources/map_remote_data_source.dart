import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/location_constants.dart';
import '../../domain/entities/map_filter_type.dart';
import '../models/map_report_model.dart';

/// Data source interface for fetching remote map reports.
abstract class MapRemoteDataSource {
  Future<List<MapReportModel>> getNearbyReports({
    double? lat,
    double? lng,
    double radiusMeters = 50000,
    String? animalType,
    MapFilterType filterType = MapFilterType.all,
  });

  Future<MapReportModel?> getReportById(String id);
}

/// Supabase PostgREST & PostGIS implementation of [MapRemoteDataSource].
///
/// Queries recorded missing pets and sightings from the database via PostGIS RPC
/// `nearby_reports`. If unreachable or empty, falls back gracefully to calibrated
/// mock & session reports.
class MapRemoteDataSourceImpl implements MapRemoteDataSource {
  final SupabaseClient? _customClient;

  MapRemoteDataSourceImpl([SupabaseClient? client]) : _customClient = client;

  /// Always resolves to a live client. Using [Supabase.instance.client] directly
  /// avoids the silent-null issue that occurred when capturing the client at
  /// construction time before the session was fully established.
  SupabaseClient get _client => _customClient ?? Supabase.instance.client;

  @override
  Future<List<MapReportModel>> getNearbyReports({
    double? lat,
    double? lng,
    double radiusMeters = 50000,
    String? animalType,
    MapFilterType filterType = MapFilterType.all,
  }) async {
    List<MapReportModel> reports = [];

    // Localized to Cebu with nationwide fallback coverage.
    // If the provided GPS coordinates fall outside Cebu province (e.g. the Android
    // emulator's default location is Googleplex, California at 37.42, -122.08),
    // clamp the query origin back to the Cebu City center so the RPC always returns
    // Cebu-region reports. The raw GPS value is still used for the map camera and the
    // user location marker — just not for the data query.
    final rawLat = lat ?? LocationConstants.defaultLatitude;
    final rawLng = lng ?? LocationConstants.defaultLongitude;
    final queryLat = LocationConstants.isWithinCebu(rawLat, rawLng)
        ? rawLat
        : LocationConstants.defaultLatitude;
    final queryLng = LocationConstants.isWithinCebu(rawLat, rawLng)
        ? rawLng
        : LocationConstants.defaultLongitude;
    if (!LocationConstants.isWithinCebu(rawLat, rawLng) && lat != null) {
      debugPrint(
        '[MapRemoteDataSourceImpl] GPS ($rawLat, $rawLng) is outside Cebu — '
        'querying from Cebu City center instead.',
      );
    }
    final queryRadius = radiusMeters < 2000000 ? 2000000.0 : radiusMeters;

    // Attempt live Supabase RPC query
    try {
      debugPrint(
        '[MapRemoteDataSourceImpl] Calling nearby_reports '
        'lat=$queryLat lng=$queryLng radius=$queryRadius',
      );

      final response = await _client.rpc(
        'nearby_reports',
        params: {
          'p_lat': queryLat,
          'p_lng': queryLng,
          'p_radius_m': queryRadius,
          // Omit p_animal_type when null or when filtering by 'Other', so the SQL query
          // returns all animals and the client-side filter captures custom species (e.g. Rabbit, Bird).
          if (animalType != null &&
              animalType.toLowerCase() != 'other' &&
              animalType.toLowerCase() != 'other animals')
            'p_animal_type': animalType,
          'p_limit': 150,
        },
      );

      debugPrint('[MapRemoteDataSourceImpl] RPC response type: ${response.runtimeType}');

      if (response is List && response.isNotEmpty) {
        reports = response
            .map((row) => MapReportModel.fromJson(row as Map<String, dynamic>))
            .toList();
        debugPrint('[MapRemoteDataSourceImpl] Parsed ${reports.length} reports from RPC.');
      } else {
        debugPrint('[MapRemoteDataSourceImpl] RPC returned empty or null.');
      }
    } catch (e) {
      debugPrint('[MapRemoteDataSourceImpl] Supabase RPC error: $e');
    }

    // If RPC returned nothing, fall back to the feed_reports view which unpacks
    // PostGIS geometry into plain lat/lng columns and includes location_name.
    if (reports.isEmpty) {
      try {
        debugPrint('[MapRemoteDataSourceImpl] RPC empty — attempting feed_reports view fallback.');
        final fallback = await _client
            .from('feed_reports')
            .select(
              'id, reporter_id, pet_id, animal_name, animal_type, description, '
              'location_name, photo_url, status, created_at, latitude, longitude',
            )
            .inFilter('status', ['missing', 'stray', 'found'])
            .order('created_at', ascending: false)
            .limit(150);

        if (fallback is List && fallback.isNotEmpty) {
          reports = fallback
              .map((row) => MapReportModel.fromViewJson(row as Map<String, dynamic>))
              .whereType<MapReportModel>()
              .toList();
          debugPrint(
            '[MapRemoteDataSourceImpl] View fallback returned ${reports.length} reports.',
          );
        }
      } catch (e) {
        debugPrint('[MapRemoteDataSourceImpl] feed_reports view fallback error: $e');
      }
    }

    // If still empty, use calibrated mock baseline so the map is never blank
    if (reports.isEmpty) {
      reports = MapReportModel.getMockReports();
    } else {
      // Merge in any newly pinned reports from the current active session
      for (final dynamicReport in MapReportModel.dynamicReports) {
        if (!reports.any((r) => r.id == dynamicReport.id)) {
          reports.insert(0, dynamicReport);
        }
      }
    }

    // Apply client-side filters
    if (animalType != null && animalType.isNotEmpty) {
      final filterLower = animalType.toLowerCase().trim();
      if (filterLower == 'other' || filterLower == 'other animals') {
        // "Other Animals" includes everything that is NOT Canine/Dog and NOT Feline/Cat
        // (e.g. Rabbit, Hamster, Bird, Reptile, custom specified species, or literal 'Other')
        reports = reports.where((r) {
          final t = r.animalType.toLowerCase().trim();
          return t != 'canine' && t != 'dog' && t != 'dogs' &&
                 t != 'feline' && t != 'cat' && t != 'cats';
        }).toList();
      } else if (filterLower == 'canine' || filterLower == 'dog') {
        reports = reports.where((r) {
          final t = r.animalType.toLowerCase().trim();
          return t == 'canine' || t == 'dog' || t == 'dogs';
        }).toList();
      } else if (filterLower == 'feline' || filterLower == 'cat') {
        reports = reports.where((r) {
          final t = r.animalType.toLowerCase().trim();
          return t == 'feline' || t == 'cat' || t == 'cats';
        }).toList();
      } else {
        reports = reports
            .where((r) => r.animalType.toLowerCase().trim() == filterLower)
            .toList();
      }
    }

    if (filterType == MapFilterType.forYou) {
      // In the SDD: "For You" surfaces reports tailored to missing pets
      reports = reports.where((r) => r.status.toLowerCase() == 'missing').toList();
    }

    // Filter to Cebu Province bounds — but always keep mock/dynamic session pins
    // (they already have valid Cebu coords) while only applying the keyword exclusion
    // to location strings explicitly naming other cities.
    const nonCebuKeywords = [
      'manila',
      'quezon city',
      'makati',
      'davao',
      'baguio',
      'cavite',
      'laguna',
      'taguig',
      'pasig',
    ];

    reports = reports.where((r) {
      // Session-injected dynamic pins are always allowed through
      final isDynamic = MapReportModel.dynamicReports.any((d) => d.id == r.id);
      if (isDynamic) return true;

      // Coordinate check — must fall within Cebu province bounding box
      if (!LocationConstants.isWithinCebu(r.latitude, r.longitude)) {
        debugPrint(
          '[MapRemoteDataSourceImpl] Dropped out-of-bounds pin '
          '${r.id} (${r.latitude}, ${r.longitude})',
        );
        return false;
      }

      // Keyword exclusion — drop only if location name explicitly names another city
      final locLower = r.locationName.toLowerCase();
      if (nonCebuKeywords.any((kw) => locLower.contains(kw))) {
        debugPrint('[MapRemoteDataSourceImpl] Dropped non-Cebu keyword pin ${r.id}');
        return false;
      }

      return true;
    }).toList();

    debugPrint(
      '[MapRemoteDataSourceImpl] Final visible pins: ${reports.length}',
    );

    return reports;
  }

  @override
  Future<MapReportModel?> getReportById(String id) async {
    // Fetch directly from the feed_reports view (unpacks PostGIS geometry)
    try {
      final row = await _client
          .from('feed_reports')
          .select(
            'id, reporter_id, pet_id, animal_name, animal_type, description, '
            'location_name, photo_url, status, created_at, latitude, longitude',
          )
          .eq('id', id)
          .maybeSingle();

      if (row != null) {
        return MapReportModel.fromViewJson(row as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('[MapRemoteDataSourceImpl] getReportById view fetch error: $e');
    }

    // Last resort: scan from the full nearby list
    try {
      final all = await getNearbyReports();
      return all.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }
}
