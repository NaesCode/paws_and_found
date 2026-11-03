/// Represents an AI visual match candidate suggested by the in-camera
/// scanner before report submission (Google Lens-style pre-matching).
class AiMatchCandidate {
  final String petId;
  final String reportId;
  final String petName;
  final String species;
  final String photoUrl;
  final double similarityScore;
  final int similarityPercent;
  final double? distanceKm;
  final String? lastSeenLocation;
  final String? ownerName;
  final DateTime? missingSince;

  AiMatchCandidate({
    required this.petId,
    required this.reportId,
    required this.petName,
    required this.species,
    required this.photoUrl,
    required this.similarityScore,
    int? similarityPercent,
    this.distanceKm,
    this.lastSeenLocation,
    this.ownerName,
    this.missingSince,
  }) : similarityPercent = similarityPercent ?? (similarityScore * 100).round();

  /// True if the confidence is high enough for a prioritized highlight (>= 80%)
  bool get isHighConfidence => similarityPercent >= 80;

  factory AiMatchCandidate.fromJson(Map<String, dynamic> json) {
    final score = (json['similarity_score'] as num?)?.toDouble() ?? 0.0;
    final percent = json['similarity_percent'] as int? ?? (score * 100).round();

    return AiMatchCandidate(
      petId: json['pet_id'] as String? ?? json['id'] as String? ?? '',
      reportId: json['report_id'] as String? ?? json['id'] as String? ?? '',
      petName: json['pet_name'] as String? ?? json['name'] as String? ?? 'Missing Pet',
      species: json['species'] as String? ?? json['animal_type'] as String? ?? 'Canine',
      photoUrl: json['photo_url'] as String? ?? '',
      similarityScore: score,
      similarityPercent: percent,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      lastSeenLocation: json['last_seen_location'] as String? ??
          json['location_name'] as String? ??
          json['location'] as String?,
      ownerName: json['owner_name'] as String? ?? json['reporter_name'] as String?,
      missingSince: json['missing_since'] != null
          ? DateTime.tryParse(json['missing_since'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'pet_id': petId,
        'report_id': reportId,
        'pet_name': petName,
        'species': species,
        'photo_url': photoUrl,
        'similarity_score': similarityScore,
        'similarity_percent': similarityPercent,
        if (distanceKm != null) 'distance_km': distanceKm,
        if (lastSeenLocation != null) 'last_seen_location': lastSeenLocation,
        if (lastSeenLocation != null) 'location_name': lastSeenLocation,
        if (ownerName != null) 'owner_name': ownerName,
        if (missingSince != null) 'missing_since': missingSince!.toIso8601String(),
      };
}
