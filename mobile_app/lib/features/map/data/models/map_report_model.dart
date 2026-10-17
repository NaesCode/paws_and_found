import '../../domain/entities/map_report_entity.dart';

/// Data class extending [MapReportEntity] with JSON serialization and mock factories.
class MapReportModel extends MapReportEntity {
  const MapReportModel({
    required super.id,
    required super.reporterId,
    super.petId,
    required super.title,
    required super.animalType,
    required super.description,
    super.photoUrl,
    required super.status,
    required super.locationName,
    required super.latitude,
    required super.longitude,
    required super.normalizedX,
    required super.normalizedY,
    super.distanceMeters,
    required super.createdAt,
    required super.tags,
  });

  /// Factory constructor to parse rows returned from Supabase queries or the
  /// `nearby_reports` PostGIS RPC.
  factory MapReportModel.fromJson(Map<String, dynamic> json) {
    final status = json['status'] as String? ?? 'stray';
    final animalType = json['animal_type'] as String? ?? 'Other';
    final desc = json['description'] as String? ?? '';
    final lat = (json['lat'] ?? json['latitude'] ?? 14.5995) as num;
    final lng = (json['lng'] ?? json['longitude'] ?? 120.9842) as num;

    // Build reasonable tags from metadata
    final List<String> extractedTags = [];
    if (json['tags'] is List) {
      extractedTags.addAll((json['tags'] as List).map((e) => e.toString()));
    } else {
      if (animalType.isNotEmpty) extractedTags.add(animalType);
      if (status.isNotEmpty) extractedTags.add(status.toUpperCase());
    }

    return MapReportModel(
      id: json['id']?.toString() ?? '',
      reporterId: json['reporter_id']?.toString() ?? '',
      petId: json['pet_id']?.toString(),
      title: json['title'] as String? ??
          (desc.isNotEmpty && desc.length < 24 ? desc : '$animalType Sighting'),
      animalType: animalType,
      description: desc,
      photoUrl: json['photo_url'] as String?,
      status: status,
      locationName: json['location_name'] as String? ?? 'Community Area',
      latitude: lat.toDouble(),
      longitude: lng.toDouble(),
      normalizedX: ((json['normalized_x'] as num?)?.toDouble() ?? 0.5)
          .clamp(0.1, 0.9),
      normalizedY: ((json['normalized_y'] as num?)?.toDouble() ?? 0.5)
          .clamp(0.1, 0.9),
      distanceMeters: (json['distance_m'] as num?)?.toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      tags: extractedTags,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporter_id': reporterId,
      'pet_id': petId,
      'title': title,
      'animal_type': animalType,
      'description': description,
      'photo_url': photoUrl,
      'status': status,
      'location_name': locationName,
      'lat': latitude,
      'lng': longitude,
      'normalized_x': normalizedX,
      'normalized_y': normalizedY,
      'distance_m': distanceMeters,
      'created_at': createdAt.toIso8601String(),
      'tags': tags,
    };
  }

  /// Initial mock reports faithfully mirroring the SDD wireframe (Page 45).
  static List<MapReportModel> getMockReports() {
    final now = DateTime.now();

    return [
      MapReportModel(
        id: 'mock-report-1',
        reporterId: 'user-001',
        title: 'Golden Retriever',
        animalType: 'Canine',
        description: 'Golden retriever spotted wandering near Elm street.',
        status: 'missing',
        locationName: 'Near Elm St',
        latitude: 14.5995,
        longitude: 120.9842,
        normalizedX: 0.28,
        normalizedY: 0.38,
        createdAt: now.subtract(const Duration(hours: 2)),
        tags: const ['Male', 'Adult', 'Golden'],
      ),
      MapReportModel(
        id: 'mock-report-2',
        reporterId: 'user-002',
        title: 'Tabby Cat',
        animalType: 'Feline',
        description: 'Striped grey tabby resting on Maple Avenue sidewalk.',
        status: 'missing',
        locationName: 'Maple Ave',
        latitude: 14.6010,
        longitude: 120.9830,
        normalizedX: 0.62,
        normalizedY: 0.45,
        createdAt: now.subtract(const Duration(minutes: 30)),
        tags: const ['Feline', 'Female', 'Grey'],
      ),
      MapReportModel(
        id: 'mock-report-3',
        reporterId: 'user-003',
        title: 'Mixed Breed Dog',
        animalType: 'Canine',
        description: 'Brown stray dog seen running towards the park.',
        status: 'stray',
        locationName: 'Park Blvd',
        latitude: 14.5980,
        longitude: 120.9855,
        normalizedX: 0.52,
        normalizedY: 0.33,
        createdAt: now.subtract(const Duration(hours: 1)),
        tags: const ['Canine', 'Large', 'Brown'],
      ),
      MapReportModel(
        id: 'mock-report-4',
        reporterId: 'user-004',
        title: 'Beagle',
        animalType: 'Canine',
        description: 'Friendly tri-color beagle found and safe at local shelter.',
        status: 'found',
        locationName: 'Oak St',
        latitude: 14.6025,
        longitude: 120.9860,
        normalizedX: 0.34,
        normalizedY: 0.30,
        createdAt: now.subtract(const Duration(hours: 3)),
        tags: const ['Canine', 'Male', 'Tri-color'],
      ),
      MapReportModel(
        id: 'mock-report-5',
        reporterId: 'user-005',
        title: 'Domestic Shorthair',
        animalType: 'Feline',
        description: 'Small stray cat near alleyway dumpster.',
        status: 'stray',
        locationName: 'Cedar Rd',
        latitude: 14.5970,
        longitude: 120.9820,
        normalizedX: 0.22,
        normalizedY: 0.48,
        createdAt: now.subtract(const Duration(hours: 4)),
        tags: const ['Feline', 'Small', 'Black'],
      ),
      MapReportModel(
        id: 'mock-report-6',
        reporterId: 'user-006',
        title: 'Shih Tzu',
        animalType: 'Canine',
        description: 'White & beige Shih Tzu found near the corner grocery.',
        status: 'found',
        locationName: 'Pine Ave',
        latitude: 14.6005,
        longitude: 120.9848,
        normalizedX: 0.40,
        normalizedY: 0.43,
        createdAt: now.subtract(const Duration(hours: 5)),
        tags: const ['Canine', 'Small', 'White/Beige'],
      ),
    ];
  }
}
