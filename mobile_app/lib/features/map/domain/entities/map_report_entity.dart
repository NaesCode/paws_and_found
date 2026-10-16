/// Domain entity representing an animal sighting or missing pet report
/// rendered on the Community Animal Map.
///
/// Adheres to Clean Architecture: pure Dart business object without framework
/// or database dependencies.
class MapReportEntity {
  final String id;
  final String reporterId;
  final String? petId;
  final String title;
  final String animalType;
  final String description;
  final String? photoUrl;
  final String status; // 'missing', 'stray', 'found'
  final String locationName;
  final double latitude;
  final double longitude;
  final double normalizedX; // relative position for canvas display (0.0 to 1.0)
  final double normalizedY; // relative position for canvas display (0.0 to 1.0)
  final double? distanceMeters;
  final DateTime createdAt;
  final List<String> tags;

  const MapReportEntity({
    required this.id,
    required this.reporterId,
    this.petId,
    required this.title,
    required this.animalType,
    required this.description,
    this.photoUrl,
    required this.status,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.normalizedX,
    required this.normalizedY,
    this.distanceMeters,
    required this.createdAt,
    required this.tags,
  });

  /// Single-letter code used for the map pin marker ('M', 'S', or 'F').
  String get pinLabel {
    switch (status.toLowerCase()) {
      case 'missing':
        return 'M';
      case 'stray':
        return 'S';
      case 'found':
        return 'F';
      default:
        return 'S';
    }
  }

  /// Human-friendly relative time string (e.g. '2h ago', '30m ago').
  String get formattedTimeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  /// Combined subtitle for the report card (e.g., "Near Elm St · 2h ago").
  String get subtitle => '$locationName · $formattedTimeAgo';
}
