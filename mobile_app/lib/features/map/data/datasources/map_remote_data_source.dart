import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/map_filter_type.dart';
import '../models/map_report_model.dart';

/// Data source interface for fetching remote map reports.
abstract class MapRemoteDataSource {
  Future<List<MapReportModel>> getNearbyReports({
    double? lat,
    double? lng,
    double radiusMeters = 5000,
    String? animalType,
    MapFilterType filterType = MapFilterType.all,
  });

  Future<MapReportModel?> getReportById(String id);
}

/// Supabase PostgREST & PostGIS implementation of [MapRemoteDataSource].
///
/// If Supabase is unreachable or returns an empty set during development,
/// gracefully falls back to the high-fidelity mock reports to preserve
/// an interactive wireframe experience.
class MapRemoteDataSourceImpl implements MapRemoteDataSource {
  final SupabaseClient? _client;

  MapRemoteDataSourceImpl([SupabaseClient? client])
      : _client = client ?? _safeGetSupabaseClient();

  static SupabaseClient? _safeGetSupabaseClient() {
    try {
      final instance = Supabase.instance;
      return instance.client.auth.currentSession != null ? instance.client : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<MapReportModel>> getNearbyReports({
    double? lat,
    double? lng,
    double radiusMeters = 5000,
    String? animalType,
    MapFilterType filterType = MapFilterType.all,
  }) async {
    List<MapReportModel> reports = [];

    // Attempt live Supabase RPC query if client is ready and coordinates provided
    if (_client != null && lat != null && lng != null) {
      try {
        final response = await _client.rpc(
          'nearby_reports',
          params: {
            'p_lat': lat,
            'p_lng': lng,
            'p_radius_m': radiusMeters,
            'p_animal_type': animalType,
            'p_limit': 100,
          },
        );

        if (response is List && response.isNotEmpty) {
          reports = response
              .map((row) => MapReportModel.fromJson(row as Map<String, dynamic>))
              .toList();
        }
      } catch (_) {
        // Fall back to mock reports on network/RPC failure during early sprints
      }
    }

    // If no records from backend, use calibrated mock reports
    if (reports.isEmpty) {
      reports = MapReportModel.getMockReports();
    }

    // Apply client-side filters
    if (animalType != null && animalType.isNotEmpty) {
      reports = reports
          .where((r) => r.animalType.toLowerCase() == animalType.toLowerCase())
          .toList();
    }

    if (filterType == MapFilterType.forYou) {
      // In the SDD: "For You" surfaces reports tailored to missing pets or closer proximity
      reports = reports.where((r) => r.status.toLowerCase() == 'missing').toList();
    }

    return reports;
  }

  @override
  Future<MapReportModel?> getReportById(String id) async {
    final all = await getNearbyReports();
    try {
      return all.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }
}
