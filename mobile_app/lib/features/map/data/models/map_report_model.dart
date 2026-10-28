import '../../../../core/constants/location_constants.dart';
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
    final status = json['status'] as String? ?? json['report_status'] as String? ?? 'stray';
    final animalType = json['animal_type'] as String? ?? 'Other';
    final desc = json['description'] as String? ?? '';
    final lat = (json['lat'] ?? json['latitude'] ?? LocationConstants.defaultLatitude) as num;
    final lng = (json['lng'] ?? json['longitude'] ?? LocationConstants.defaultLongitude) as num;

    // Build reasonable tags from metadata
    final List<String> extractedTags = [];
    if (json['tags'] is List) {
      extractedTags.addAll((json['tags'] as List).map((e) => e.toString()));
    } else {
      if (animalType.isNotEmpty) extractedTags.add(animalType);
      if (status.isNotEmpty) extractedTags.add(status.toUpperCase());
    }

    final petId = json['pet_id']?.toString();
    String? rawTitle = json['title'] as String?;
    String title;
    if (rawTitle != null && rawTitle.isNotEmpty) {
      title = rawTitle;
    } else if (petId == 'cc4df92c-64e9-4e9e-b37c-507ed997966f') {
      title = 'Thomas';
    } else if (petId == '1d205292-31b4-472f-8450-1c0b0d1653ef') {
      title = 'Bruno';
    } else if (desc.toLowerCase().contains('meowki')) {
      title = 'Meowki';
    } else if (desc.isNotEmpty && desc.length < 24) {
      title = desc;
    } else {
      title = '$animalType Sighting';
    }

    String locationName = json['location_name'] as String? ?? '';
    if (locationName.isEmpty || locationName == 'Community Area') {
      if (desc.toLowerCase().contains('lawaan')) {
        locationName = 'Lawaan, Talisay, Cebu';
      } else if (desc.toLowerCase().contains('emall')) {
        locationName = 'Elizabeth Mall, Cebu';
      } else if ((lat - 10.3).abs() < 0.4 && (lng - 123.9).abs() < 0.4) {
        locationName = 'Cebu City';
      } else {
        locationName = 'Cebu Community Area';
      }
    }

    return MapReportModel(
      id: json['id']?.toString() ?? '',
      reporterId: json['reporter_id']?.toString() ?? '',
      petId: petId,
      title: title,
      animalType: animalType,
      description: desc,
      photoUrl: json['photo_url'] as String?,
      status: status,
      locationName: locationName,
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

  /// In-memory storage for newly submitted or pinned reports during the session.
  static final List<MapReportModel> _dynamicReports = [];

  /// Returns unmodifiable list of dynamic session reports.
  static List<MapReportModel> get dynamicReports => List.unmodifiable(_dynamicReports);

  /// Registers a newly created or pinned report so it renders immediately on the map canvas.
  static void addReport(MapReportModel report) {
    _dynamicReports.removeWhere((r) => r.id == report.id);
    _dynamicReports.insert(0, report);
  }

  /// Clears dynamic reports (used primarily for test resets).
  static void clearDynamicReports() {
    _dynamicReports.clear();
  }

  /// Baseline reports representing the actual missing and sighted animals recorded
  /// in the Supabase database, prepended with dynamically created session reports.
  static List<MapReportModel> getMockReports() {
    final now = DateTime.now();

    final baseReports = [
      MapReportModel(
        id: '8f91a575-653f-4071-a9c8-549152a1cad1',
        petId: 'cc4df92c-64e9-4e9e-b37c-507ed997966f',
        reporterId: '6116799b-0f5c-4dff-80f1-05b9bb3200c7',
        title: 'Thomas',
        animalType: 'Feline',
        description: 'Last seen outside house gate in Lawaan. Moggy / Domestic Shorthair, Gray with white spots and paws.',
        status: 'missing',
        locationName: 'Lawaan, Talisay, Cebu',
        latitude: 10.2578691,
        longitude: 123.8207739,
        normalizedX: 0.35,
        normalizedY: 0.40,
        photoUrl: 'https://pbbrnlytulbaylsbpagx.supabase.co/storage/v1/object/public/animal-photos/6116799b-0f5c-4dff-80f1-05b9bb3200c7/8f222ae3-2cb6-4565-bd3f-cc4874ee102e.jpg',
        createdAt: now.subtract(const Duration(hours: 4)),
        tags: const ['Feline', 'Male', 'Gray & White'],
      ),
      MapReportModel(
        id: 'e6a25b3b-0bc2-4253-bbd5-619c9678fb83',
        petId: '1d205292-31b4-472f-8450-1c0b0d1653ef',
        reporterId: '6116799b-0f5c-4dff-80f1-05b9bb3200c7',
        title: 'Bruno',
        animalType: 'Canine',
        description: 'He was last seen in emall, ran inside the mall. Shepweiler (German Shepherd & Rottweiler).',
        status: 'missing',
        locationName: 'Elizabeth Mall (E-Mall), Cebu City',
        latitude: 10.2982,
        longitude: 123.8975,
        normalizedX: 0.55,
        normalizedY: 0.48,
        photoUrl: 'https://pbbrnlytulbaylsbpagx.supabase.co/storage/v1/object/public/animal-photos/6116799b-0f5c-4dff-80f1-05b9bb3200c7/d4a8c234-5643-4964-86e1-c31410162e76.jpg',
        createdAt: now.subtract(const Duration(hours: 12)),
        tags: const ['Canine', 'Adult', 'Shepweiler'],
      ),
      MapReportModel(
        id: '1d9a923b-9121-4968-9e59-07870fddb191',
        reporterId: '5533261d-53e5-4950-8548-37f0b9afa039',
        title: 'Meowki',
        animalType: 'Feline',
        description: 'Her name is Meowki. Missing cat last seen near Lahug.',
        status: 'missing',
        locationName: 'Lahug, Cebu City',
        latitude: LocationConstants.cebuITPark.latitude,
        longitude: LocationConstants.cebuITPark.longitude,
        normalizedX: 0.45,
        normalizedY: 0.35,
        photoUrl: 'https://pbbrnlytulbaylsbpagx.supabase.co/storage/v1/object/public/animal-photos/5533261d-53e5-4950-8548-37f0b9afa039/efcc44cd-823f-4c8c-b4fb-77318993ed3a.jpg',
        createdAt: now.subtract(const Duration(hours: 2)),
        tags: const ['Feline', 'Missing', 'Cebu'],
      ),
      MapReportModel(
        id: 'c1e8142c-3a48-4458-b1bb-273c32c4c2c6',
        reporterId: 'bee2de6b-4ef4-4460-921e-ebaf9a320a9c',
        title: 'Big Black Dog',
        animalType: 'Canine',
        description: 'Big Black Dog. Have a brown spot on its neck.',
        status: 'found',
        locationName: 'Cebu City',
        latitude: 10.3157,
        longitude: 123.8854,
        normalizedX: 0.60,
        normalizedY: 0.32,
        createdAt: now.subtract(const Duration(days: 1)),
        tags: const ['Canine', 'Black', 'Found'],
      ),
    ];

    return [..._dynamicReports, ...baseReports];
  }
}
