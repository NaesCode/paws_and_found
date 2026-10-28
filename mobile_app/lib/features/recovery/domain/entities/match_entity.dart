enum MatchDecision {
  confirm,
  reject,
}

enum MatchStatus {
  pending,
  confirmed,
  rejected,
}

enum MatchTriggeredBy {
  report,
  pet,
}

class MatchEntity {
  final String id;
  final String reportId;
  final String petId;
  final double similarityScore;
  final double distanceMeters;
  final MatchStatus status;
  final MatchTriggeredBy triggeredBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const MatchEntity({
    required this.id,
    required this.reportId,
    required this.petId,
    required this.similarityScore,
    required this.distanceMeters,
    required this.status,
    required this.triggeredBy,
    required this.createdAt,
    this.updatedAt,
  });
}

