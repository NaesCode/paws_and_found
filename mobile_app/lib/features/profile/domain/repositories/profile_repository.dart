import '../entities/user_profile.dart';
import '../entities/pet.dart';

abstract class ProfileRepository {
  /// Fetches the authenticated user's profile from the backend.
  Future<UserProfile> getProfile();

  /// Updates the user's editable profile fields via PATCH /api/me/.
  Future<UserProfile> updateProfile({
    String? name,
    String? phoneNumber,
    String? address,
    String? bio,
    String? profilePhotoURL,
  });

  /// Fetches the user's registered pets.
  Future<List<Pet>> getPets();

  /// Reports a registered pet as missing.
  Future<void> reportPetMissing(String petId);

  /// Marks a missing pet as safe.
  Future<void> markPetSafe(String petId);
}

