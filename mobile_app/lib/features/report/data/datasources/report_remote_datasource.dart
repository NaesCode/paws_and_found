import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/report.dart';
import '../models/report_model.dart';

/// Abstract contract for the report data source.
abstract class ReportRemoteDataSource {
  Future<List<SightingReport>> getNearbyReports({
    required double lat,
    required double lng,
    double radiusM = 5000,
    String? animalType,
    int limit = 200,
  });

  Future<String> uploadReportPhoto(Uint8List bytes, {String extension = 'jpg'});

  Future<String> createReport({
    required String animalType,
    required String description,
    required String photoUrl,
    required double lat,
    required double lng,
    String status = 'stray',
    String? petId,
  });
}

/// Concrete implementation that talks directly to Supabase.
class ReportRemoteDataSourceImpl implements ReportRemoteDataSource {
  final SupabaseClient _supabase;

  ReportRemoteDataSourceImpl({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  // ---------------------------------------------------------------------------
  // Get Nearby Reports
  // ---------------------------------------------------------------------------

  /// Calls the `nearby_reports` PostGIS RPC which returns rows with
  /// distance-ordered sighting reports within [radiusM] metres.
  ///
  /// The RPC signature (in SQL) is:
  ///   nearby_reports(lat float8, lng float8, radius_m float8, animal_type text, lim int)
  @override
  Future<List<SightingReport>> getNearbyReports({
    required double lat,
    required double lng,
    double radiusM = 5000,
    String? animalType,
    int limit = 200,
  }) async {
    final response = await _supabase.rpc('nearby_reports', params: {
      'lat': lat,
      'lng': lng,
      'radius_m': radiusM,
      'animal_type': animalType, // null means "all types" in the RPC
      'lim': limit,
    });

    if (response == null) return [];

    final List<dynamic> rows = response as List<dynamic>;
    return rows
        .map((row) => SightingReportModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Upload Report Photo
  // ---------------------------------------------------------------------------

  /// Uploads a photo to the `animal-photos` bucket under
  /// `{user_id}/{uuid}.{extension}` and returns the public URL.
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

    final publicUrl =
        _supabase.storage.from('animal-photos').getPublicUrl(path);
    return publicUrl;
  }

  // ---------------------------------------------------------------------------
  // Create Report
  // ---------------------------------------------------------------------------

  /// Calls the `create_report` Postgres RPC which atomically inserts a report
  /// row and returns its generated UUID.
  ///
  /// The RPC signature (in SQL) is:
  ///   create_report(animal_type text, description text, photo_url text,
  ///                 lat float8, lng float8, status text, pet_id uuid)
  @override
  Future<String> createReport({
    required String animalType,
    required String description,
    required String photoUrl,
    required double lat,
    required double lng,
    String status = 'stray',
    String? petId,
  }) async {
    final response = await _supabase.rpc('create_report', params: <String, dynamic>{
      'animal_type': animalType,
      'description': description,
      'photo_url': photoUrl,
      'lat': lat,
      'lng': lng,
      'status': status,
      'pet_id': ?petId,
    });

    if (response == null) throw Exception('create_report RPC returned null');
    return response as String;
  }
}

