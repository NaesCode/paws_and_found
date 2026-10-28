import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/orchestrator_client.dart';
import '../../domain/entities/match_entity.dart';
import '../../domain/repositories/match_repository.dart';
import '../models/match_model.dart';

class MatchRepositoryImpl implements MatchRepository {
  final SupabaseClient _supabase;
  final OrchestratorClient _orchestratorClient;

  MatchRepositoryImpl({
    SupabaseClient? supabaseClient,
    OrchestratorClient? orchestratorClient,
  })  : _supabase = supabaseClient ?? Supabase.instance.client,
        _orchestratorClient = orchestratorClient ?? OrchestratorClient();

  @override
  Future<List<MatchEntity>> getMatches() async {
    final response = await _supabase
        .from('matches')
        .select()
        .order('similarity_score', ascending: false);

    return (response as List<dynamic>)
        .map((row) => MatchModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> respondToMatch(String matchId, MatchDecision decision) async {
    final decisionStr = decision == MatchDecision.confirm ? 'confirm' : 'reject';
    await _orchestratorClient.post(
      '/api/matches/$matchId/respond/',
      body: {'decision': decisionStr},
    );
  }
}

