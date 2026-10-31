class FeedPost {
  final String id;
  final String reporterId;
  final String? petId;
  final String species;
  final String description;
  final String imageUrl;
  final String location;
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
    // String get petName => petId ?? "Unknown Pet";
    final petMap = json['pets'] as Map<String, dynamic>?;
    final parsedPetName = (petMap?['name'] as String? ?? '').isNotEmpty 
        ? petMap!['name'] as String 
        : "Unknown Pet";
    
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

    return FeedPost(
      id: json['id']?.toString() ?? '',
      reporterId: json['reporter_id']?.toString() ?? '',
      petId: json['pet_id']?.toString(),
      species: json['animal_type'] as String? ?? 'Other',
      description: json['description'] as String? ?? '',
      imageUrl: cleanImageUrl,
      location: json['location_name'] as String? ?? '',
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
}
