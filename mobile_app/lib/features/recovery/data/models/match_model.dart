import '../../domain/entities/match_entity.dart';

class MatchModel extends MatchEntity {
  const MatchModel({
    required super.id,
    required super.reportId,
    required super.petId,
    required super.similarityScore,
    required super.distanceMeters,
    required super.status,
    required super.triggeredBy,
    required super.createdAt,
    super.updatedAt,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    MatchStatus parseStatus(String? val) {
      switch (val?.toLowerCase()) {
        case 'confirmed':
          return MatchStatus.confirmed;
        case 'rejected':
          return MatchStatus.rejected;
        case 'pending':
        default:
          return MatchStatus.pending;
      }
    }

    MatchTriggeredBy parseTriggeredBy(String? val) {
      switch (val?.toLowerCase()) {
        case 'pet':
          return MatchTriggeredBy.pet;
        case 'report':
        default:
          return MatchTriggeredBy.report;
      }
    }

    return MatchModel(
      id: json['id'] as String,
      reportId: json['report_id'] as String,
      petId: json['pet_id'] as String,
      similarityScore: (json['similarity_score'] as num?)?.toDouble() ?? 0.0,
      distanceMeters: (json['distance_meters'] as num?)?.toDouble() ?? 0.0,
      status: parseStatus(json['status'] as String?),
      triggeredBy: parseTriggeredBy(json['triggered_by'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }
}

