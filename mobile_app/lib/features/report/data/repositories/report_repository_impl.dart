import 'package:flutter/foundation.dart';
import '../../../../core/network/orchestrator_client.dart';
import '../../domain/entities/report.dart';
import '../../domain/repositories/report_repository.dart';
import '../datasources/report_remote_datasource.dart';

/// Bridges the domain's [ReportRepository] interface and the
/// [ReportRemoteDataSourceImpl] that talks to Supabase and the AI micro-orchestrator.
class ReportRepositoryImpl implements ReportRepository {
  final ReportRemoteDataSource _dataSource;
  final OrchestratorClient _orchestratorClient;

  ReportRepositoryImpl({
    ReportRemoteDataSource? dataSource,
    OrchestratorClient? orchestratorClient,
  })  : _dataSource = dataSource ?? ReportRemoteDataSourceImpl(),
        _orchestratorClient = orchestratorClient ?? OrchestratorClient();

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

  /// Prepared for Phase 4: AI Feature Extraction & Candidate Matching.
  ///
  /// Ready for the AI micro-orchestrator team:
  /// When the containerized Django service is deployed, this method triggers
  /// the PyTorch/OpenCV pipeline (POST /api/reports/{id}/analyze/) using the
  /// authenticated user's Supabase JWT.
  @override
  Future<void> requestReportAnalysis(String reportId) async {
    // -------------------------------------------------------------------------
    // AI Integration Pipeline Hook:
    // Dispatches analysis request to the containerized Django micro-orchestrator.
    // The orchestrator generates PyTorch feature embeddings & performs GeoDjango
    // candidate spatial matching against missing pets within 5km.
    // -------------------------------------------------------------------------
    try {
      await _orchestratorClient.post('/api/reports/$reportId/analyze/');
      debugPrint('[ReportRepositoryImpl] AI analysis requested for report: $reportId');
    } catch (e) {
      // Non-fatal: if orchestrator is offline/pending deployment, the sighting
      // report remains safely stored in Supabase with 'analysis_status: pending'.
      debugPrint('[ReportRepositoryImpl] AI analysis dispatch deferred (backend offline): $e');
    }
  }
}

