import '../../domain/entities/feed_post.dart';

class PetPostModel extends FeedPost {
  const PetPostModel({
    required super.id,
    required super.petName,
    required super.postedBy,
    required super.species,
    required super.location,
    required super.description,
    required super.imageUrl,
    required super.status,
    required super.hoursAgo,
    required super.formattedTime,
    super.latitude,
    super.longitude,
  });

  factory PetPostModel.fromJoinedData(
    Map<String, dynamic> postRaw,
    Map<String, dynamic>? userRaw,
  ) {
    final DateTime createdAt = DateTime.parse(postRaw['created_at'] as String);
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(createdAt);
    final int hours = difference.inHours;
    final String formatted = hours <= 0 ? "Just now" : "${hours}h ago";

    final lat = (postRaw['lat'] ?? postRaw['latitude'] as num?)?.toDouble();
    final lng = (postRaw['lng'] ?? postRaw['longitude'] as num?)?.toDouble();

    // Sanitize location string: If the database returned a raw PostGIS EWKB hex string,
    // convert it to human-readable coordinates instead of displaying machine code.
    final String rawLocation =
        postRaw['location_name']?.toString() ??
        postRaw['location_text']?.toString() ??
        postRaw['location']?.toString() ??
        '';
    final String displayLocation;
    if (rawLocation.startsWith('01010000') || rawLocation.length > 32) {
      if (lat != null && lng != null) {
        displayLocation =
            '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
      } else {
        displayLocation = 'Nearby Location';
      }
    } else if (rawLocation.trim().isNotEmpty) {
      displayLocation = rawLocation;
    } else if (lat != null && lng != null) {
      displayLocation = '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
    } else {
      displayLocation = 'Cebu, Philippines';
    }

    final String postedBy =
        userRaw != null && (userRaw['name'] as String?)?.isNotEmpty == true
        ? userRaw['name'] as String
        : (postRaw['reporter_name'] as String? ?? "Community Member");

    return PetPostModel(
      id: postRaw['id']?.toString() ?? '',
      petName: postRaw['pet_name'] as String? ?? "Unnamed Pet",
      postedBy: postedBy,
      species:
          postRaw['species'] as String? ??
          postRaw['animal_type'] as String? ??
          "Unknown",
      location: displayLocation,
      description: postRaw['description'] as String? ?? '',
      imageUrl:
          postRaw['image_url'] as String? ??
          postRaw['photo_url'] as String? ??
          '',
      status: postRaw['status'] as String? ?? 'spotted',
      hoursAgo: hours < 0 ? 0 : hours,
      formattedTime: formatted,
      latitude: lat,
      longitude: lng,
    );
  }

  factory PetPostModel.fromJson(Map<String, dynamic> json) {
    return PetPostModel.fromJoinedData(json, null);
  }
}
