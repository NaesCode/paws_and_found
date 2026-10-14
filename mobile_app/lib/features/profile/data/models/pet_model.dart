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

    return PetModel(
      petID: (json['petID'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      species: (json['species'] as String?) ?? 'Pet',
      breed: json['breed'] as String?,
      description: json['description'] as String?,
      photoURLs: (json['photoURLs'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      status: petStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'petID': petID,
      'name': name,
      'species': species,
      'breed': breed,
      'description': description,
      'photoURLs': photoURLs,
      'status': status.name,
    };
  }
}

