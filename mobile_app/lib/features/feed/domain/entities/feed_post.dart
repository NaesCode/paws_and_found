/// Domain entity representing a community feed report post.
class FeedPost {
  final String id;
  final String petName;
  final String postedBy;
  final String species;
  final String location;
  final String description;
  final String imageUrl;
  final String status;
  final int hoursAgo;
  final String formattedTime;

  const FeedPost({
    required this.id,
    required this.petName,
    required this.postedBy,
    required this.species,
    required this.location,
    required this.description,
    required this.imageUrl,
    required this.status,
    required this.hoursAgo,
    required this.formattedTime,
  });
}
