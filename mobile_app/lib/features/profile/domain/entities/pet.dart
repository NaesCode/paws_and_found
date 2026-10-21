enum PetStatus {
  safe,
  missing,
  recovered,
}

/// Represents a registered pet entity in the domain layer.
class Pet {
  final String petID;
  final String name;
  final String species;
  final String? breed;
  final String? description;
  final List<String> photoURLs;
  final PetStatus status;

  const Pet({
    required this.petID,
    required this.name,
    required this.species,
    this.breed,
    this.description,
    this.photoURLs = const [],
    this.status = PetStatus.safe,
  });

  /// Formatted species/breed string, avoiding duplicate species words (e.g. "Ginger Cat", not "Ginger Cat Cat").
  String get displaySpecies {
    if (breed != null && breed!.trim().isNotEmpty) {
      final cleanBreed = breed!.trim();
      final cleanSpecies = species.trim();
      final regex = RegExp(r'\b' + RegExp.escape(cleanSpecies) + r'\b', caseSensitive: false);
      if (regex.hasMatch(cleanBreed)) {
        return cleanBreed;
      }
      return '$cleanBreed $cleanSpecies';
    }
    return species;
  }

  Pet copyWith({
    String? petID,
    String? name,
    String? species,
    String? breed,
    String? description,
    List<String>? photoURLs,
    PetStatus? status,
  }) {
    return Pet(
      petID: petID ?? this.petID,
      name: name ?? this.name,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      description: description ?? this.description,
      photoURLs: photoURLs ?? this.photoURLs,
      status: status ?? this.status,
    );
  }
}
