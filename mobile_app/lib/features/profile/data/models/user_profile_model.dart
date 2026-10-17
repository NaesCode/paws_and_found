import '../../domain/entities/user_profile.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.userID,
    required super.name,
    required super.email,
    super.phoneNumber,
    super.address,
    super.bio,
    super.profilePhotoURL,
    super.dateRegistered,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      userID: (json['id'] ?? json['userID'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      phoneNumber: (json['phone_number'] ?? json['phoneNumber']) as String?,
      address: json['address'] as String?,
      bio: json['bio'] as String?,
      profilePhotoURL: (json['profile_photo_url'] ?? json['profilePhotoURL']) as String?,
      dateRegistered: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : (json['dateRegistered'] != null ? DateTime.tryParse(json['dateRegistered'] as String) : null),
    );
  }

  Map<String, dynamic> toSupabaseUpdate() {
    final Map<String, dynamic> data = {};
    if (name.isNotEmpty) data['name'] = name;
    if (phoneNumber != null) data['phone_number'] = phoneNumber;
    if (address != null) data['address'] = address;
    if (bio != null) data['bio'] = bio;
    if (profilePhotoURL != null) data['profile_photo_url'] = profilePhotoURL;
    return data;
  }
}
