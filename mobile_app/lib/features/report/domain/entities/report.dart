class SightingReport {
  final String id;
  final String reporterId;
  final String? petId;
  final String animalType;
  final String description;
  final String photoUrl;
  final String status;
  final String analysisStatus;
  final DateTime createdAt;
  final double lat;
  final double lng;
  final double? distanceMeters;

  const SightingReport({
    required this.id,
    required this.reporterId,
    this.petId,
    required this.animalType,
    required this.description,
    required this.photoUrl,
    required this.status,
    required this.analysisStatus,
    required this.createdAt,
    required this.lat,
    required this.lng,
    this.distanceMeters,
  });

  bool get isAnalysisPending => analysisStatus == 'pending';
  bool get isAnalysisDone => analysisStatus == 'done';
}

