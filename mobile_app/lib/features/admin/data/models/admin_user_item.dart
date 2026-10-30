/// Represents a user item in the Admin User Management wireframe (Screen 09)
/// with full credential and permission properties for administrative modifications.
class AdminUserItem {
  final String id;
  final String name;
  final String emailMasked;
  final String fullEmail;
  final String phoneNumber;
  final int reputation;
  final String status; // 'Active' or 'Suspended'
  final String role; // 'User' or 'Admin'
  final bool canPostReports;
  final bool canClaimAnimals;
  final String? avatarUrl;

  const AdminUserItem({
    required this.id,
    required this.name,
    required this.emailMasked,
    this.fullEmail = '',
    this.phoneNumber = '',
    this.reputation = 0,
    required this.status,
    this.role = 'User',
    this.canPostReports = true,
    this.canClaimAnimals = true,
    this.avatarUrl,
  });

  bool get isActive => status.toLowerCase() == 'active';
  bool get isWarning => status.toLowerCase() == 'warning';
  bool get isSuspended => status.toLowerCase().contains('suspend');
  bool get isAdmin => role.toLowerCase() == 'admin';

  AdminUserItem copyWith({
    String? id,
    String? name,
    String? emailMasked,
    String? fullEmail,
    String? phoneNumber,
    int? reputation,
    String? status,
    String? role,
    bool? canPostReports,
    bool? canClaimAnimals,
    String? avatarUrl,
  }) {
    return AdminUserItem(
      id: id ?? this.id,
      name: name ?? this.name,
      emailMasked: emailMasked ?? this.emailMasked,
      fullEmail: fullEmail ?? this.fullEmail,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      reputation: reputation ?? this.reputation,
      status: status ?? this.status,
      role: role ?? this.role,
      canPostReports: canPostReports ?? this.canPostReports,
      canClaimAnimals: canClaimAnimals ?? this.canClaimAnimals,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  factory AdminUserItem.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? '') as String;
    final rawName = (json['name'] as String?)?.trim();
    final email = (json['email'] as String?)?.trim() ?? '';

    // Display name priority: profile name -> email handle -> 'Anonymous User'
    String displayName = 'Anonymous User';
    if (rawName != null && rawName.isNotEmpty) {
      displayName = rawName;
    } else if (email.isNotEmpty) {
      displayName = email.split('@').first;
    }

    // Masked email format: e.g. "m.." or "j.." matching wireframe SDD Screen 09
    String masked = '--';
    if (email.isNotEmpty) {
      masked = '${email[0].toLowerCase()}..';
    }

    return AdminUserItem(
      id: id,
      name: displayName,
      emailMasked: masked,
      fullEmail: email,
      phoneNumber: (json['phone_number'] as String?) ?? '',
      reputation: (json['reputation'] as num?)?.toInt() ?? 0,
      status: (json['status'] as String?) ?? 'Active',
      role: (json['role'] as String?) ?? 'User',
      canPostReports: (json['can_post_reports'] as bool?) ?? true,
      canClaimAnimals: (json['can_claim_animals'] as bool?) ?? true,
      avatarUrl: json['profile_photo_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': fullEmail,
      'phone_number': phoneNumber,
      'reputation': reputation,
      'status': status,
      'role': role,
      'can_post_reports': canPostReports,
      'can_claim_animals': canClaimAnimals,
      'profile_photo_url': avatarUrl,
    };
  }


}
