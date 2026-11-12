import 'dart:async' show unawaited;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:paws_and_found/core/network/orchestrator_client.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/pet.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;
  final OrchestratorClient _orchestratorClient;

  ProfileRepositoryImpl({
    ProfileRemoteDataSource? remoteDataSource,
    OrchestratorClient? orchestratorClient,
  })  : remoteDataSource = remoteDataSource ?? ProfileRemoteDataSourceImpl(),
        _orchestratorClient = orchestratorClient ?? OrchestratorClient();

  @override
  Future<UserProfile> getProfile() async {
    return await remoteDataSource.getProfile();
  }

  @override
  Future<UserProfile> updateProfile({
    String? name,
    String? phoneNumber,
    String? address,
    String? bio,
    String? profilePhotoURL,
  }) async {
    final Map<String, dynamic> fields = {};
    if (name != null) fields['name'] = name;
    if (phoneNumber != null) fields['phone_number'] = phoneNumber;
    if (address != null) fields['address'] = address;
    if (bio != null) fields['bio'] = bio;

    if (profilePhotoURL != null) {
      fields['profile_photo_url'] = profilePhotoURL;
      try {
        // Fetch the user's current profile data to check for an existing photo
        final currentProfile = await remoteDataSource.getProfile();
        final String? oldUrl = currentProfile.profilePhotoURL;

        // Only run deletion if a photo existed and it is actually changing
        if (oldUrl != null && oldUrl.isNotEmpty && oldUrl != profilePhotoURL) {
          // Token matches the 'user-profile-photo' storage path structure
          final String storageUrlMatchToken = '/storage/v1/object/public/user-profile-photo/';

          if (oldUrl.contains(storageUrlMatchToken)) {
            final relativePath = oldUrl.split(storageUrlMatchToken).last;

            final supabase = Supabase.instance.client;

            // Security Check: Enforce that users can only delete out of their own folder
            if (relativePath.startsWith('${currentProfile.userID}/')) {
              await supabase.storage
                  .from('user-profile-photo')
                  .remove([relativePath]);
              debugPrint('[ProfileRepositoryImpl] Cleaned up old profile photo: $relativePath');
            }
          }
        }
      } catch (storageError) {
        debugPrint('[ProfileRepositoryImpl] Profile photo storage cleanup deferred: $storageError');
      }
    }
    // if (profilePhotoURL != null) fields['profile_photo_url'] = profilePhotoURL;
    return await remoteDataSource.updateProfile(fields);
  }

  @override
  Future<List<Pet>> getPets() async {
    return await remoteDataSource.getPets();
  }

  @override
  Future<String> uploadPetPhoto(Uint8List bytes, {String extension = 'jpg'}) async {
    return await remoteDataSource.uploadPetPhoto(bytes, extension: extension);
  }

  @override
  Future<String> uploadProfilePhoto(Uint8List bytes, {String extension = 'jpg'}) async {
    return await remoteDataSource.uploadProfilePhoto(bytes, extension: extension);
  }

  @override
  Future<Pet> addPet({
    required String name,
    required String species,
    String? breed,
    String? color,
    String? description,
    List<String> photoUrls = const [],
  }) async {
    final pet = await remoteDataSource.addPet(
      name: name,
      species: species,
      breed: breed,
      color: color,
      description: description,
      photoUrls: photoUrls,
    );

    // Asynchronously dispatch AI pet embedding extraction to Django orchestrator
    if (pet.photoURLs.isNotEmpty && !pet.petID.startsWith('mock-')) {
      unawaited(_requestPetAnalysis(pet.petID));
    }

    return pet;
  }

  @override
  Future<Pet> updatePet({
    required String petId,
    String? name,
    String? species,
    String? breed,
    String? color,
    String? description,
    List<String>? photoUrls,
  }) async {
    // 1. Delete-before-upload logic if photoUrls changed (including when removed)
    if (photoUrls != null) {
      try {
        final currentPets = await remoteDataSource.getPets();
        final matches = currentPets.where((p) => p.petID == petId);
        final currentPet = matches.isNotEmpty ? matches.first : null;
        final oldPhoto = (currentPet != null && currentPet.photoURLs.isNotEmpty)
            ? currentPet.photoURLs.first
            : null;
        final newPhoto = photoUrls.isNotEmpty ? photoUrls.first : null;

        if (oldPhoto != null && oldPhoto.isNotEmpty && (photoUrls.isEmpty || oldPhoto != newPhoto)) {
          const storageUrlMatchToken = '/storage/v1/object/public/animal-photos/';
          if (oldPhoto.contains(storageUrlMatchToken)) {
            final relativePath = oldPhoto.split(storageUrlMatchToken).last;
            final supabase = Supabase.instance.client;
            final currentUserId = supabase.auth.currentUser?.id;

            if (currentUserId != null && relativePath.startsWith('$currentUserId/')) {
              await supabase.storage.from('animal-photos').remove([relativePath]);
              debugPrint('[ProfileRepositoryImpl] Cleaned up old pet photo: $relativePath');
            }
          }
        }
      } catch (storageError) {
        debugPrint('[ProfileRepositoryImpl] Pet photo storage cleanup deferred: $storageError');
      }
    }

    // 2. Commit update to Supabase
    final updatedPet = await remoteDataSource.updatePet(
      petId,
      name: name,
      species: species,
      breed: breed,
      color: color,
      description: description,
      photoUrls: photoUrls,
    );

    // 3. AI re-embedding & reverse matching dispatch:
    // If the photo was updated, force-refresh the embedding vector on the Django orchestrator.
    // Also if the pet is currently missing, the orchestrator's PetAnalyzeView re-runs reverse matching.
    if (!petId.startsWith('mock-')) {
      final photoWasUpdated = photoUrls != null && photoUrls.isNotEmpty;
      unawaited(_requestPetAnalysis(petId, refresh: photoWasUpdated));
    }

    return updatedPet;
  }

  @override
  Future<void> deletePet(String petId, {String? reason, String? details}) async {
    return await remoteDataSource.deletePet(petId, reason: reason, details: details);
  }

  @override
  Future<void> reportPetMissing(
    String petId, {
    double? lat,
    double? lng,
    String? note,
    DateTime? missingSince,
  }) async {
    await remoteDataSource.reportPetMissing(
      petId,
      lat: lat,
      lng: lng,
      note: note,
      missingSince: missingSince,
    );

    // Ensure pet visual embedding is up to date in private.pet_embeddings for reverse matching
    if (!petId.startsWith('mock-')) {
      unawaited(_requestPetAnalysis(petId));
    }
  }

  @override
  Future<void> markPetSafe(String petId) async {
    return await remoteDataSource.markPetSafe(petId);
  }

  /// Dispatches a request to Django's /api/pets/{id}/analyze/ to compute
  /// and upsert visual embeddings into private.pet_embeddings.
  Future<void> _requestPetAnalysis(String petId, {bool refresh = false}) async {
    try {
      await _orchestratorClient.post(
        '/api/pets/$petId/analyze/',
        body: refresh ? {'refresh': true} : null,
      );
      debugPrint('[ProfileRepositoryImpl] AI analysis requested for pet: $petId (refresh=$refresh)');
    } catch (e) {
      // Non-fatal: if orchestrator is offline, the pet is still safely saved in Supabase
      debugPrint('[ProfileRepositoryImpl] Pet AI analysis dispatch deferred: $e');
    }
  }
}
