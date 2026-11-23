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
        final currentProfile = await remoteDataSource.getProfile();
        final String? oldUrl = currentProfile.profilePhotoURL;

        if (oldUrl != null && oldUrl.isNotEmpty && oldUrl != profilePhotoURL) {
          const String storageUrlMatchToken = '/storage/v1/object/public/user-profile-photo/';

          if (oldUrl.contains(storageUrlMatchToken)) {
            final relativePath = oldUrl.split(storageUrlMatchToken).last;
            final supabase = Supabase.instance.client;

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
    String alertSound = 'cat',
  }) async {
    final pet = await remoteDataSource.addPet(
      name: name,
      species: species,
      breed: breed,
      color: color,
      description: description,
      photoUrls: photoUrls,
      alertSound: alertSound,
    );

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
    String? alertSound,
  }) async {
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

    final updatedPet = await remoteDataSource.updatePet(
      petId,
      name: name,
      species: species,
      breed: breed,
      color: color,
      description: description,
      photoUrls: photoUrls,
      alertSound: alertSound,
    );

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

    if (!petId.startsWith('mock-')) {
      unawaited(_requestPetAnalysis(petId));
    }
  }

  @override
  Future<void> markPetSafe(String petId) async {
    return await remoteDataSource.markPetSafe(petId);
  }

  @override
  Stream<List<dynamic>> watchPendingMeetups() async* {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id ?? '';
    if (userId.isEmpty) {
      yield [];
      return;
    }

    Future<List<dynamic>> fetchActive() async {
      final rows = await client
          .from('pet_claims')
          .select()
          .or('finder_id.eq.$userId,claimer_id.eq.$userId')
          .neq('status', 'completed')
          .neq('status', 'declined')
          .order('updated_at', ascending: false);

      final List<dynamic> items = [];
      for (final row in rows) {
        final reportId = row['report_id']?.toString() ?? '';
        final isFinder = row['finder_id'] == userId;
        final otherUserId = isFinder
            ? (row['claimer_id']?.toString() ?? '')
            : (row['finder_id']?.toString() ?? '');

        Map<String, dynamic>? report;
        if (reportId.isNotEmpty) {
          report = await client
              .from('reports')
              .select()
              .eq('id', reportId)
              .maybeSingle();
        }

        Map<String, dynamic>? otherProfile;
        if (otherUserId.isNotEmpty) {
          otherProfile = await client
              .from('profiles')
              .select()
              .eq('id', otherUserId)
              .maybeSingle();
        }

        final rawName = (report?['animal_name'] ?? '').toString().trim();
        final animalType = (report?['animal_type'] ?? 'Pet').toString().trim();
        final petTitle = rawName.isNotEmpty ? rawName : 'Spotted $animalType';

        // Support both photo_url (text) and photo_urls (list)
        String photoUrl = (report?['photo_url'] ?? '').toString();
        if (photoUrl.isEmpty && report?['photo_urls'] is List) {
          final list = report!['photo_urls'] as List;
          if (list.isNotEmpty) photoUrl = list.first.toString();
        }

        final otherName = (otherProfile?['name'] ??
                otherProfile?['username'] ??
                (isFinder ? 'Claimant' : 'Finder'))
            .toString();

        items.add({
          'claimId': row['id']?.toString() ?? '',
          'reportId': reportId,
          'isFinder': isFinder,
          'currentStage': row['current_stage'] ?? 1,
          'petTitle': petTitle,
          'photoUrl': photoUrl,
          'otherPartyName': otherName,
          'meetupPlace': row['meetup_place']?.toString(),
          'meetupTime': row['meetup_time']?.toString(),
          'meetupAgreed': (row['meetup_confirmed_by_finder'] == true) &&
              (row['meetup_confirmed_by_claimer'] == true),
          'myHandoverConfirmed': isFinder
              ? (row['finder_confirmed_handover'] == true)
              : (row['claimer_confirmed_handover'] == true),
        });
      }
      return items;
    }

    // 1. Emit immediately on load
    yield await fetchActive();

    // 2. Re-emit whenever pet_claims changes in Realtime (if enabled)
    yield* client
        .from('pet_claims')
        .stream(primaryKey: ['id'])
        .asyncMap((_) => fetchActive());
  }

  @override
  Stream<List<dynamic>> watchCompletedReunions() async* {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id ?? '';
    if (userId.isEmpty) {
      yield [];
      return;
    }

    Future<List<dynamic>> fetchCompleted() async {
      final rows = await client
          .from('pet_claims')
          .select()
          .or('finder_id.eq.$userId,claimer_id.eq.$userId')
          .eq('status', 'completed')
          .order('updated_at', ascending: false);

      return _mapClaimRows(client, rows, userId);
    }

    // 1. Emit immediately on load
    yield await fetchCompleted();

    // 2. Re-emit whenever pet_claims updates in Realtime
    yield* client
        .from('pet_claims')
        .stream(primaryKey: ['id'])
        .asyncMap((_) => fetchCompleted());
  }

  Future<List<dynamic>> _mapClaimRows(
    SupabaseClient client,
    List<dynamic> rows,
    String userId,
  ) async {
    final List<dynamic> items = [];
    for (final row in rows) {
      final reportId = row['report_id']?.toString() ?? '';
      final isFinder = row['finder_id'] == userId;
      final otherUserId = isFinder
          ? (row['claimer_id']?.toString() ?? '')
          : (row['finder_id']?.toString() ?? '');

      Map<String, dynamic>? report;
      if (reportId.isNotEmpty) {
        report = await client
            .from('reports')
            .select()
            .eq('id', reportId)
            .maybeSingle();
      }

      Map<String, dynamic>? otherProfile;
      if (otherUserId.isNotEmpty) {
        otherProfile = await client
            .from('profiles')
            .select()
            .eq('id', otherUserId)
            .maybeSingle();
      }

      final rawName = (report?['animal_name'] ?? '').toString().trim();
      final animalType = (report?['animal_type'] ?? 'Pet').toString().trim();
      final petTitle = rawName.isNotEmpty ? rawName : 'Spotted $animalType';

      String photoUrl = (report?['photo_url'] ?? '').toString();
      if (photoUrl.isEmpty && report?['photo_urls'] is List) {
        final list = report!['photo_urls'] as List;
        if (list.isNotEmpty) photoUrl = list.first.toString();
      }

      final otherName = (otherProfile?['name'] ??
              otherProfile?['username'] ??
              (isFinder ? 'Claimant' : 'Finder'))
          .toString();

      items.add({
        'claimId': row['id']?.toString() ?? '',
        'reportId': reportId,
        'isFinder': isFinder,
        'currentStage': row['current_stage'] ?? 1,
        'petTitle': petTitle,
        'photoUrl': photoUrl,
        'otherPartyName': otherName,
        'meetupPlace': row['meetup_place']?.toString(),
        'meetupTime': row['meetup_time']?.toString(),
        'updatedAt': row['updated_at']?.toString(),
        'meetupAgreed': (row['meetup_confirmed_by_finder'] == true) &&
            (row['meetup_confirmed_by_claimer'] == true),
        'myHandoverConfirmed': isFinder
            ? (row['finder_confirmed_handover'] == true)
            : (row['claimer_confirmed_handover'] == true),
      });
    }
    return items;
  }

  @override
  Future<Set<String>> getFlaggedPetNames() async {
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) return {};

    try {
      final List<dynamic> rows = await client
          .from('notifications')
          .select('message')
          .eq('user_id', uid)
          .eq('type', 'warning')
          .like('message', '%Pet Profile Under Review%');

      final flagged = <String>{};
      final regex = RegExp(r"Pet Profile Under Review:\s*'([^']+)'");
      for (final r in rows) {
        final msg = r['message']?.toString() ?? '';
        final match = regex.firstMatch(msg);
        if (match != null && match.group(1) != null) {
          flagged.add(match.group(1)!);
        }
      }
      return flagged;
    } catch (_) {
      return {};
    }
  }

  Future<void> _requestPetAnalysis(String petId, {bool refresh = false}) async {
    try {
      await _orchestratorClient.post(
        '/api/pets/$petId/analyze/',
        body: refresh ? {'refresh': true} : null,
      );
      debugPrint('[ProfileRepositoryImpl] AI analysis requested for pet: $petId (refresh=$refresh)');
    } catch (e) {
      debugPrint('[ProfileRepositoryImpl] Pet AI analysis dispatch deferred: $e');
    }
  }
}