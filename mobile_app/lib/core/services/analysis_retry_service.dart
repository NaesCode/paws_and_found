import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../network/orchestrator_client.dart';

class AnalysisRetryService {
  final SupabaseClient _supabase;
  final OrchestratorClient _orchestratorClient;

  AnalysisRetryService({
    SupabaseClient? supabaseClient,
    OrchestratorClient? orchestratorClient,
  })  : _supabase = supabaseClient ?? Supabase.instance.client,
        _orchestratorClient = orchestratorClient ?? OrchestratorClient();

  /// Runs non-blocking background sweep for any pending reports or missing pets
  /// that require AI analysis.
  Future<void> sweepPendingAnalyses() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Sweep pending reports older than 1 minute (max 5 per launch)
      final oneMinuteAgo = DateTime.now().toUtc().subtract(const Duration(minutes: 1)).toIso8601String();
      final List<dynamic> pendingReports = await _supabase
          .from('reports')
          .select('id')
          .eq('reporter_id', user.id)
          .eq('analysis_status', 'pending')
          .lte('created_at', oneMinuteAgo)
          .order('created_at', ascending: true)
          .limit(5);

      for (final row in pendingReports) {
        final reportId = row['id']?.toString();
        if (reportId != null && reportId.isNotEmpty) {
          unawaited(_reanalyzeReport(reportId));
        }
      }

      // 2. Sweep missing pets owned by user (max 5 per launch)
      final List<dynamic> missingPets = await _supabase
          .from('pets')
          .select('id')
          .eq('owner_id', user.id)
          .eq('status', 'missing')
          .limit(5);

      for (final row in missingPets) {
        final petId = row['id']?.toString();
        if (petId != null && !petId.startsWith('mock-')) {
          unawaited(_reanalyzePet(petId));
        }
      }
    } catch (e) {
      debugPrint('[AnalysisRetryService] Sweep error (non-fatal): $e');
    }
  }

  Future<void> _reanalyzeReport(String reportId) async {
    try {
      await _orchestratorClient.post('/api/reports/$reportId/analyze/');
      debugPrint('[AnalysisRetryService] Swept pending report: $reportId');
    } catch (e) {
      debugPrint('[AnalysisRetryService] Failed to sweep report $reportId: $e');
    }
  }

  Future<void> _reanalyzePet(String petId) async {
    try {
      await _orchestratorClient.post('/api/pets/$petId/analyze/');
      debugPrint('[AnalysisRetryService] Swept missing pet: $petId');
    } catch (e) {
      debugPrint('[AnalysisRetryService] Failed to sweep pet $petId: $e');
    }
  }
}

