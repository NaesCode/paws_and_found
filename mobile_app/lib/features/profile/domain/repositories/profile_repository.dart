import 'dart:typed_data';
import '../entities/user_profile.dart';
import '../entities/pet.dart';

abstract class ProfileRepository {
  /// Fetches the authenticated user's profile directly from Supabase.
  Future<UserProfile> getProfile();

  /// Updates the user's editable profile fields via Supabase PostgREST.
  Future<UserProfile> updateProfile({
    String? name,
    String? phoneNumber,
    String? address,
    String? bio,
    String? profilePhotoURL,
  });

  /// Fetches the user's registered pets.
  Future<List<Pet>> getPets();

  /// Uploads a pet photo to the 'animal-photos' Supabase Storage bucket.
  Future<String> uploadPetPhoto(Uint8List bytes, {String extension = 'jpg'});

  /// Adds a new registered pet for the current user.
  Future<Pet> addPet({
    required String name,
    required String species,
    String? breed,
    String? color,
    String? description,
    List<String> photoUrls = const [],
  });

  /// Deletes a registered pet.
  Future<void> deletePet(String petId);

  /// Reports a registered pet as missing.
  Future<void> reportPetMissing(String petId, {double? lat, double? lng, String? note});

  /// Marks a missing pet as safe.
  Future<void> markPetSafe(String petId);
}
