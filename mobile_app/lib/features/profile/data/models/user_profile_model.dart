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
      userID: (json['userID'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      address: json['address'] as String?,
      bio: json['bio'] as String?,
      profilePhotoURL: json['profilePhotoURL'] as String?,
      dateRegistered: json['dateRegistered'] != null
          ? DateTime.tryParse(json['dateRegistered'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (name.isNotEmpty) data['name'] = name;
    if (phoneNumber != null) data['phoneNumber'] = phoneNumber;
    if (address != null) data['address'] = address;
    if (bio != null) data['bio'] = bio;
    if (profilePhotoURL != null) data['profilePhotoURL'] = profilePhotoURL;
    return data;
  }
}

