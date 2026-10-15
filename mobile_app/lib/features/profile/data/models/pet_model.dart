import '../../domain/entities/pet.dart';

class PetModel extends Pet {
  const PetModel({
    required super.petID,
    required super.name,
    required super.species,
    super.breed,
    super.description,
    super.photoURLs,
    super.status,
  });

  factory PetModel.fromJson(Map<String, dynamic> json) {
    PetStatus petStatus = PetStatus.safe;
    final statusStr = (json['status'] as String?)?.toLowerCase();
    if (statusStr == 'missing') {
      petStatus = PetStatus.missing;
    } else if (statusStr == 'recovered') {
      petStatus = PetStatus.recovered;
    }

    final rawPhotos = json['photo_urls'] ?? json['photoURLs'];

    return PetModel(
      petID: (json['id'] ?? json['petID'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      species: (json['species'] ?? 'Pet') as String,
      breed: json['breed'] as String?,
      description: json['description'] as String?,
      photoURLs: rawPhotos is List ? rawPhotos.map((e) => e.toString()).toList() : const [],
      status: petStatus,
    );
  }

  Map<String, dynamic> toSupabaseInsert(String ownerId) {
    return {
      'owner_id': ownerId,
      'name': name,
      'species': species,
      if (breed != null) 'breed': breed,
      if (description != null) 'description': description,
      'photo_urls': photoURLs,
    };
  }
}
