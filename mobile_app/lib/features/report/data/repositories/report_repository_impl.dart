import 'dart:typed_data';

import '../../domain/entities/report.dart';
import '../../domain/repositories/report_repository.dart';
import '../datasources/report_remote_datasource.dart';

/// Bridges the domain's [ReportRepository] interface and the
/// [ReportRemoteDataSourceImpl] that talks to Supabase.
///
/// This layer is the "glue" — it catches raw datasource errors and re-throws
/// them as domain-level exceptions so the presentation layer stays clean.
class ReportRepositoryImpl implements ReportRepository {
  final ReportRemoteDataSource _dataSource;

  ReportRepositoryImpl({ReportRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? ReportRemoteDataSourceImpl();

  @override
  Future<List<SightingReport>> getNearbyReports({
    required double lat,
    required double lng,
    double radiusM = 5000,
    String? animalType,
    int limit = 200,
  }) async {
    try {
      return await _dataSource.getNearbyReports(
        lat: lat,
        lng: lng,
        radiusM: radiusM,
        animalType: animalType,
        limit: limit,
      );
    } catch (e) {
      throw Exception('Failed to load nearby reports: $e');
    }
  }

  @override
  Future<String> uploadReportPhoto(
    Uint8List bytes, {
    String extension = 'jpg',
  }) async {
    try {
      return await _dataSource.uploadReportPhoto(bytes, extension: extension);
    } catch (e) {
      throw Exception('Failed to upload report photo: $e');
    }
  }

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
    try {
      return await _dataSource.createReport(
        animalType: animalType,
        description: description,
        photoUrl: photoUrl,
        lat: lat,
        lng: lng,
        status: status,
        petId: petId,
      );
    } catch (e) {
      throw Exception('Failed to create report: $e');
    }
  }

  /// Requesting analysis from the Django orchestrator is intentionally
  /// left as a no-op until Phase 4 (AI endpoints) is implemented.
  /// The orchestrator will be wired here then.
  @override
  Future<void> requestReportAnalysis(String reportId) async {
    // TODO(Phase 4): Call OrchestratorClient.post('/api/reports/$reportId/analyze/')
    return;
  }
}

