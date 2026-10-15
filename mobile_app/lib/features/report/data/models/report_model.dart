import '../../domain/entities/report.dart';

class SightingReportModel extends SightingReport {
  const SightingReportModel({
    required super.id,
    required super.reporterId,
    super.petId,
    required super.animalType,
    required super.description,
    required super.photoUrl,
    required super.status,
    required super.analysisStatus,
    required super.createdAt,
    required super.lat,
    required super.lng,
    super.distanceMeters,
  });

  factory SightingReportModel.fromJson(Map<String, dynamic> json) {
    return SightingReportModel(
      id: (json['id'] ?? '') as String,
      reporterId: (json['reporter_id'] ?? '') as String,
      petId: json['pet_id'] as String?,
      animalType: (json['animal_type'] ?? 'Unknown') as String,
      description: (json['description'] ?? '') as String,
      photoUrl: (json['photo_url'] ?? '') as String,
      status: (json['status'] ?? 'stray') as String,
      analysisStatus: (json['analysis_status'] ?? 'pending') as String,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      lat: ((json['lat'] ?? 0.0) as num).toDouble(),
      lng: ((json['lng'] ?? 0.0) as num).toDouble(),
      distanceMeters: json['distance_m'] != null ? ((json['distance_m'] as num).toDouble()) : null,
    );
  }
}

