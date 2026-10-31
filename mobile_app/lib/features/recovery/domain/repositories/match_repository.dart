import '../entities/match_entity.dart';

abstract class MatchRepository {
  /// Fetches matches visible to the authenticated user.
  /// RLS on `matches` limits results to rows where the user is either the
  /// report's reporter or the pet's owner.
  Future<List<MatchEntity>> getMatches();

  /// Responds to a pending match with either 'confirm' or 'reject'.
  /// Dispatches to the orchestrator endpoint POST /api/matches/{id}/respond/.
  Future<void> respondToMatch(String matchId, MatchDecision decision);
}

