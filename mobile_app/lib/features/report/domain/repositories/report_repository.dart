import 'dart:typed_data';
import '../entities/report.dart';

abstract class ReportRepository {
  /// Fetches community reports nearby via the 'nearby_reports' RPC function.
  Future<List<SightingReport>> getNearbyReports({
    required double lat,
    required double lng,
    double radiusM = 5000,
    String? animalType,
    int limit = 200,
  });

  /// Uploads a report photo to Supabase Storage 'animal-photos/{user_id}/{uuid}.jpg'.
  Future<String> uploadReportPhoto(Uint8List bytes, {String extension = 'jpg'});

  /// Creates a report atomically via the 'create_report' RPC function,
  /// then triggers orchestrator analysis in the background.
  Future<String> createReport({
    required String animalType,
    required String description,
    required String photoUrl,
    required double lat,
    required double lng,
    String status = 'stray',
    String? petId,
    String? locationName,
    String? linkedReportId,
  });

  /// Explicitly requests analysis from the Django orchestrator for a pending report.
  Future<void> requestReportAnalysis(String reportId);
}

