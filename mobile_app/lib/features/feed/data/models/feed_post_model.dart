import 'dart:typed_data';
import 'package:paws_and_found/core/constants/location_constants.dart';

class FeedPost {
  final String id;
  final String reporterId;
  final String? petId;
  final String species;
  final String description;
  final String imageUrl;
  final String location;
  final double? latitude;
  final double? longitude;
  final String status;
  final String analysisStatus;
  final String moderationStatus;
  final DateTime createdAt;
  final String username;
  final String userImageUrl;
  final String petName;

  FeedPost({
    required this.id,
    required this.reporterId,
    this.petId,
    required this.species,
    required this.description,
    required this.imageUrl,
    required this.location,
    this.latitude,
    this.longitude,
    required this.status,
    required this.analysisStatus,
    this.moderationStatus = 'approved',
    required this.createdAt,
    required this.username,
    required this.userImageUrl,
    required this.petName,
  });
  
  // Updated: Returns the actual profile name fetched from the database
  String get postedBy => username.isNotEmpty ? username : "Anonymous User";
  
  bool get isFlagged => moderationStatus.toLowerCase() == 'flagged';

  String get formattedTime {
    final difference = DateTime.now().difference(createdAt);
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    return 'Just now';
  }

  factory FeedPost.fromJson(Map<String, dynamic> json) {
    // UI display getters matching your ReportCardItem requirements
    final petMap = json['pets'] as Map<String, dynamic>?;
    
    final registeredPetName = (petMap?['name'] as String? ?? '').trim();
    final sightingAnimalName = (json['animal_name'] as String? ?? '').trim();

    final String parsedPetName = registeredPetName.isNotEmpty
        ? registeredPetName
        : (sightingAnimalName.isNotEmpty ? sightingAnimalName : "Unknown Pet");
  
    final profileMap = json['profiles'] as Map<String, dynamic>?;
    
    final parsedName = profileMap?['name'] as String? ?? '';
    final petImage = profileMap?['profile_photo_url'] as String? ?? '';
    final cleanPetImageUrl = (petImage.isEmpty || 
                           petImage.toLowerCase() == 'none' || 
                           petImage.toLowerCase() == 'null')
        ? ''
        : petImage;

    final rawPhotoUrl = json['photo_url'] as String? ?? '';
    final cleanImageUrl = (rawPhotoUrl.isEmpty || 
                           rawPhotoUrl.toLowerCase() == 'none' || 
                           rawPhotoUrl.toLowerCase() == 'null')
        ? ''
        : rawPhotoUrl;

    // 1. Extract coordinates if present
    double? latitude;
    double? longitude;

    if (json['latitude'] != null) {
      latitude = (json['latitude'] as num).toDouble();
    } else if (json['lat'] != null) {
      latitude = (json['lat'] as num).toDouble();
    }
    if (json['longitude'] != null) {
      longitude = (json['longitude'] as num).toDouble();
    } else if (json['lng'] != null) {
      longitude = (json['lng'] as num).toDouble();
    }

    // 2. Fall back to parsing the PostGIS 'location' field if coordinates are still missing
    if (latitude == null || longitude == null) {
      final rawLocation = json['location'];
      if (rawLocation is Map) {
        final coords = rawLocation['coordinates'];
        if (coords is List && coords.length >= 2) {
          longitude = (coords[0] as num).toDouble();
          latitude = (coords[1] as num).toDouble();
        }
      } else if (rawLocation is String && rawLocation.isNotEmpty) {
        final coords = _parseCoordinatesFromHexEWKB(rawLocation);
        if (coords != null) {
          latitude = coords.$1;
          longitude = coords.$2;
        }
      }
    }

    // 3. Resolve locationName
    String locationName = (json['location_name'] as String? ?? '').trim();
    final desc = json['description'] as String? ?? '';

    // If location_name is empty or generic, resolve it from coordinates and metadata
    if (locationName.isEmpty ||
        locationName == 'Community Area' ||
        locationName.toLowerCase() == 'no location pinned' ||
        locationName.toLowerCase() == 'unknown location') {
      if (latitude != null && longitude != null) {
        final descLower = desc.toLowerCase();
        if (descLower.contains('lawaan')) {
          locationName = 'Lawaan, Talisay, Cebu';
        } else if (descLower.contains('emall') || descLower.contains('elizabeth mall')) {
          locationName = 'Elizabeth Mall, Cebu';
        } else if ((latitude - 10.3).abs() < 0.4 && (longitude - 123.9).abs() < 0.4) {
          locationName = LocationConstants.defaultCityName; // 'Cebu City'
        } else if (LocationConstants.isWithinCebu(latitude, longitude)) {
          locationName = 'Cebu Community Area';
        } else {
          locationName = '${latitude.toStringAsFixed(4)}°, ${longitude.toStringAsFixed(4)}°';
        }
      }
    }

    return FeedPost(
      id: json['id']?.toString() ?? '',
      reporterId: json['reporter_id']?.toString() ?? '',
      petId: json['pet_id']?.toString(),
      species: json['animal_type'] as String? ?? 'Other',
      description: desc,
      imageUrl: cleanImageUrl,
      location: locationName,
      latitude: latitude,
      longitude: longitude,
      status: json['status'] as String? ?? 'Missing',
      analysisStatus: json['analysis_status'] as String? ?? 'Pending',
      moderationStatus: json['moderation_status'] as String? ?? 'approved',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      username: parsedName,
      userImageUrl: cleanPetImageUrl,
      petName: parsedPetName,
    );
  }

  static (double, double)? _parseCoordinatesFromHexEWKB(String hexStr) {
    try {
      final clean = hexStr.trim();
      if (clean.length < 42 || clean.toLowerCase() == 'null') return null;

      final List<int> bytes = [];
      for (int i = 0; i < clean.length; i += 2) {
        bytes.add(int.parse(clean.substring(i, i + 2), radix: 16));
      }

      final Uint8List uint8list = Uint8List.fromList(bytes);
      final ByteData byteData = ByteData.sublistView(uint8list);

      final int byteOrder = byteData.getUint8(0);
      final Endian endian = byteOrder == 1 ? Endian.little : Endian.big;

      final int type = byteData.getUint32(1, endian);
      // In PostGIS EWKB, flag 0x20000000 indicates SRID presence
      final bool hasSrid = (type & 0x20000000) != 0;
      final int offset = hasSrid ? 9 : 5;

      if (uint8list.length < offset + 16) return null;

      final double lng = byteData.getFloat64(offset, endian);
      final double lat = byteData.getFloat64(offset + 8, endian);

      if (lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180 && !(lat == 0 && lng == 0)) {
        return (lat, lng);
      }
    } catch (_) {}
    return null;
  }
}
