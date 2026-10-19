class PetPostModel {
  final String id;
  final String petName;    // Pet name
  final String postedBy;   // Person's name from the other table
  final String species;
  final String location;
  final String description;
  final String imageUrl;
  final String status;
  final int hoursAgo;
  final String formattedTime;

  PetPostModel({
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
