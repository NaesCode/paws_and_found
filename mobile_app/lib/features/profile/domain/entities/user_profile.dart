/// Represents the user's profile entity in the domain layer.
class UserProfile {
  final String userID;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? address;
  final String? bio;
  final String? profilePhotoURL;
  final DateTime? dateRegistered;
  final String status;

  const UserProfile({
    required this.userID,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.address,
    this.bio,
    this.profilePhotoURL,
    this.dateRegistered,
    this.status = 'Active',
  });

  /// Whether the user account has been suspended.
  bool get isSuspended => status.toLowerCase().contains('suspend');

  /// Whether the user account is currently under a warning status.
  bool get isWarning => status.toLowerCase() == 'warning';

  /// Evaluates whether the onboarding/profile setup is completed.
  /// Requires both contact/phone number and address to be set.
  bool get isProfileComplete {
    final p = phoneNumber?.trim();
    final a = address?.trim();
    return p != null && p.isNotEmpty && a != null && a.isNotEmpty;
  }

  UserProfile copyWith({
    String? userID,
    String? name,
    String? email,
    String? phoneNumber,
    String? address,
    String? bio,
    String? profilePhotoURL,
    DateTime? dateRegistered,
    String? status,
  }) {
    return UserProfile(
      userID: userID ?? this.userID,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      bio: bio ?? this.bio,
      profilePhotoURL: profilePhotoURL ?? this.profilePhotoURL,
      dateRegistered: dateRegistered ?? this.dateRegistered,
      status: status ?? this.status,
    );
  }
}

