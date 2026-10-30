/// Represents a post item in the Admin Post Management wireframe (Screen 10).
class AdminPostItem {
  final String id;
  final String rawId;
  final String title;
  final String? subtitle;
  final String status; // 'missing', 'stray', 'found'
  final String dateFormatted; // e.g. 'Sep 20'
  final String username; // e.g. 'maria_s'
  final bool isFlagged;
  final String? photoUrl;
  final String? description;
  final String? reporterId;

  const AdminPostItem({
    required this.id,
    String? rawId,
    required this.title,
    this.subtitle,
    required this.status,
    required this.dateFormatted,
    required this.username,
    this.isFlagged = false,
    this.photoUrl,
    this.description,
    this.reporterId,
  }) : rawId = rawId ?? id;

  bool get isMissing => status.toLowerCase() == 'missing';
  bool get isStray => status.toLowerCase() == 'stray';
  bool get isFound => status.toLowerCase() == 'found';

  factory AdminPostItem.fromJson(Map<String, dynamic> json) {
    final rawId = (json['id'] ?? '').toString();

    // Display ID formatting (e.g. #041 or #3FA8)
    String displayId;
    if (rawId.startsWith('#')) {
      displayId = rawId;
    } else if (rawId.length >= 4) {
      final clean = rawId.replaceAll('-', '');
      displayId = '#${clean.substring(0, clean.length >= 4 ? 4 : clean.length).toUpperCase()}';
    } else if (rawId.isNotEmpty) {
      displayId = '#$rawId';
    } else {
      displayId = '#---';
    }

    // Status: 'missing', 'stray', 'found'
    final rawStatus =
        (json['status'] as String?)?.toLowerCase().trim() ?? 'stray';

    // Date formatting: e.g. 'Sep 20'
    String dateFormatted = 'Recent';
    if (json['created_at'] != null) {
      final parsedDate = DateTime.tryParse(json['created_at'].toString());
      if (parsedDate != null) {
        const months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec'
        ];
        dateFormatted = '${months[parsedDate.month - 1]} ${parsedDate.day}';
      }
    }

    // Pet / Animal Title & Subtitle
    final pet = json['pets'] as Map<String, dynamic>?;
    final animalType = (json['animal_type'] as String?)?.trim() ?? 'Animal';
    final description = (json['description'] as String?)?.trim() ?? '';

    String title;
    String? subtitle;

    if (pet != null) {
      final petName = (pet['name'] as String?)?.trim();
      final petBreed = (pet['breed'] as String?)?.trim();
      final petSpecies = (pet['species'] as String?)?.trim();

      if (petName != null && petName.isNotEmpty) {
        title = petName;
        subtitle = (petBreed != null && petBreed.isNotEmpty)
            ? petBreed
            : (petSpecies != null && petSpecies.isNotEmpty
                ? petSpecies
                : animalType);
      } else if (petBreed != null && petBreed.isNotEmpty) {
        title = petBreed;
        subtitle = petSpecies != null && petSpecies.isNotEmpty
            ? petSpecies
            : animalType;
      } else {
        title = animalType;
        subtitle = petSpecies;
      }
    } else {
      // If animal_type has multiple words (e.g. "Golden Retriever", "Tabby Cat")
      final parts = animalType.split(RegExp(r'\s+'));
      if (parts.length > 1) {
        title = parts[0];
        subtitle = parts.sublist(1).join(' ');
      } else {
        title = animalType;
        subtitle = null;
      }
    }

    // Username from joined profiles or email handle
    final profile = json['profiles'] as Map<String, dynamic>?;
    String username = 'anonymous';
    if (profile != null) {
      final name = (profile['name'] as String?)?.trim();
      final email = (profile['email'] as String?)?.trim();
      if (name != null && name.isNotEmpty) {
        username = name;
      } else if (email != null && email.isNotEmpty) {
        username = email.split('@').first;
      }
    } else if (json['reporter_id'] != null) {
      final repId = json['reporter_id'].toString();
      username = 'user_${repId.length >= 4 ? repId.substring(0, 4) : repId}';
    }

    // Flagged state: check is_flagged, flagged, or analysis_status == 'failed'
    final isFlagged = (json['is_flagged'] as bool?) ??
        (json['flagged'] as bool?) ??
        (json['analysis_status'] == 'failed');

    return AdminPostItem(
      id: displayId,
      rawId: rawId,
      title: title,
      subtitle: subtitle,
      status: rawStatus,
      dateFormatted: dateFormatted,
      username: username,
      isFlagged: isFlagged,
      photoUrl: json['photo_url'] as String?,
      description: description,
      reporterId: json['reporter_id'] as String?,
    );
  }
}
