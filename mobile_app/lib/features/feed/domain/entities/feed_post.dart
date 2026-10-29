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
  final double? latitude;
  final double? longitude;

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
    this.latitude,
    this.longitude,
  });

  FeedPost copyWithLocation(String newLocation) {
    return FeedPost(
      id: id,
      petName: petName,
      postedBy: postedBy,
      species: species,
      location: newLocation,
      description: description,
      imageUrl: imageUrl,
      status: status,
      hoursAgo: hoursAgo,
      formattedTime: formattedTime,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
