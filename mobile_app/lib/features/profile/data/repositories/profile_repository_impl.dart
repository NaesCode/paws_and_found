import 'dart:async' show unawaited;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../../../../core/network/orchestrator_client.dart';
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
    if (profilePhotoURL != null) fields['profile_photo_url'] = profilePhotoURL;

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
  Future<void> deletePet(String petId) async {
    return await remoteDataSource.deletePet(petId);
  }

  @override
  Future<void> reportPetMissing(String petId, {double? lat, double? lng, String? note}) async {
    await remoteDataSource.reportPetMissing(petId, lat: lat, lng: lng, note: note);

    // Ensure pet visual embedding is up to date in private.pet_embeddings for matching
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
  Future<void> _requestPetAnalysis(String petId) async {
    try {
      await _orchestratorClient.post('/api/pets/$petId/analyze/');
      debugPrint('[ProfileRepositoryImpl] AI analysis requested for pet: $petId');
    } catch (e) {
      // Non-fatal: if orchestrator is offline, the pet is still safely saved in Supabase
      debugPrint('[ProfileRepositoryImpl] Pet AI analysis dispatch deferred: $e');
    }
  }
}
