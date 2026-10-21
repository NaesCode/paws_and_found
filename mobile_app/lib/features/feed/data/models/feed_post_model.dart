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

    return PetPostModel(
      id: postRaw['id'] as String,
      petName: postRaw['pet_name'] as String? ?? "Unnamed Pet",
      postedBy: userRaw != null ? userRaw['name'] as String : "Unknown User",
      species: postRaw['species'] as String,
      location: postRaw['location'] as String,
      description: postRaw['description'] as String,
      imageUrl: postRaw['image_url'] as String,
      status: postRaw['status'] as String,
      hoursAgo: hours < 0 ? 0 : hours,
      formattedTime: formatted,
    );
  }
}
