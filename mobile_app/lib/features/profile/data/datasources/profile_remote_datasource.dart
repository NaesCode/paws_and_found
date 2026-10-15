import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/user_profile_model.dart';
import '../models/pet_model.dart';
import '../../domain/entities/pet.dart';

abstract class ProfileRemoteDataSource {
  Future<UserProfileModel> getProfile();
  Future<UserProfileModel> updateProfile(Map<String, dynamic> fields);
  Future<List<PetModel>> getPets();
  Future<String> uploadPetPhoto(Uint8List bytes, {String extension = 'jpg'});
  Future<PetModel> addPet({
    required String name,
    required String species,
    String? breed,
    String? color,
    String? description,
    List<String> photoUrls = const [],
  });
  Future<void> deletePet(String petId);
  Future<void> reportPetMissing(String petId, {double? lat, double? lng, String? note});
  Future<void> markPetSafe(String petId);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final SupabaseClient supabase;

  ProfileRemoteDataSourceImpl({SupabaseClient? supabaseClient})
      : supabase = supabaseClient ?? Supabase.instance.client;

  String? get _currentUserId => supabase.auth.currentUser?.id;

  @override
  Future<UserProfileModel> getProfile() async {
    final uid = _currentUserId;
    if (uid == null) {
      throw Exception('User is not authenticated');
    }

    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', uid)
        .single();

    return UserProfileModel.fromJson(data);
  }

  @override
  Future<UserProfileModel> updateProfile(Map<String, dynamic> fields) async {
    final uid = _currentUserId;
    if (uid == null) {
      throw Exception('User is not authenticated');
    }

    final updatePayload = <String, dynamic>{};
    if (fields.containsKey('name')) updatePayload['name'] = fields['name'];
    if (fields.containsKey('phoneNumber')) updatePayload['phone_number'] = fields['phoneNumber'];
    if (fields.containsKey('phone_number')) updatePayload['phone_number'] = fields['phone_number'];
    if (fields.containsKey('address')) updatePayload['address'] = fields['address'];
    if (fields.containsKey('bio')) updatePayload['bio'] = fields['bio'];
    if (fields.containsKey('profilePhotoURL')) updatePayload['profile_photo_url'] = fields['profilePhotoURL'];
    if (fields.containsKey('profile_photo_url')) updatePayload['profile_photo_url'] = fields['profile_photo_url'];

    final data = await supabase
        .from('profiles')
        .update(updatePayload)
        .eq('id', uid)
        .select()
        .single();

    return UserProfileModel.fromJson(data);
  }

  @override
  Future<String> uploadPetPhoto(Uint8List bytes, {String extension = 'jpg'}) async {
    final uid = _currentUserId;
    if (uid == null) {
      throw Exception('User is not authenticated');
    }

    final fileUuid = const Uuid().v4();
    final path = '$uid/$fileUuid.$extension';

    await supabase.storage.from('animal-photos').uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: 'image/$extension', upsert: true),
    );

    return supabase.storage.from('animal-photos').getPublicUrl(path);
  }

  @override
  Future<PetModel> addPet({
    required String name,
    required String species,
    String? breed,
    String? color,
    String? description,
    List<String> photoUrls = const [],
  }) async {
    final uid = _currentUserId;
    if (uid == null) {
      throw Exception('User is not authenticated');
    }

    final insertPayload = <String, dynamic>{
      'owner_id': uid,
      'name': name,
      'species': species,
      'breed': ?breed,
      'color': ?color,
      'description': ?description,
      'photo_urls': photoUrls,
      'status': 'safe',
    };

    final data = await supabase
        .from('pets')
        .insert(insertPayload)
        .select()
        .single();

    return PetModel.fromJson(data);
  }

  @override
  Future<void> deletePet(String petId) async {
    final uid = _currentUserId;
    if (uid == null) {
      throw Exception('User is not authenticated');
    }

    await supabase.from('pets').delete().eq('id', petId).eq('owner_id', uid);
  }

  // --- Mock fixtures fallback if user has no pets yet ---
  static final List<PetModel> _mockPets = [
    const PetModel(
      petID: 'mock-pet-1',
      name: 'Banana',
      species: 'Cat',
      breed: 'Tabby',
      description:
          'The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog.',
      photoURLs: ['https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?auto=format&fit=crop&w=400&q=80'],
      status: PetStatus.safe,
    ),
    const PetModel(
      petID: 'mock-pet-2',
      name: 'Mochi',
      species: 'Cat',
      breed: 'Calico',
      description:
          'A gentle calico cat with distinct white and brown markings. Loves napping in sunny spots.',
      photoURLs: ['https://images.unsplash.com/photo-1573865526739-10659fec78a5?auto=format&fit=crop&w=400&q=80'],
      status: PetStatus.safe,
    ),
  ];

  @override
  Future<List<PetModel>> getPets() async {
    final uid = _currentUserId;
    if (uid == null) {
      return List.from(_mockPets);
    }

    try {
      final List<dynamic> data = await supabase
          .from('pets')
          .select()
          .eq('owner_id', uid)
          .order('created_at', ascending: false);

      if (data.isEmpty) {
        return List.from(_mockPets);
      }

      return data.map((json) => PetModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (_) {
      return List.from(_mockPets);
    }
  }

  @override
  Future<void> reportPetMissing(String petId, {double? lat, double? lng, String? note}) async {
    if (petId.startsWith('mock-')) {
      final index = _mockPets.indexWhere((p) => p.petID == petId);
      if (index != -1) {
        _mockPets[index] = _mockPets[index].copyWith(status: PetStatus.missing) as PetModel;
      }
      return;
    }

    await supabase.rpc('report_pet_missing', params: {
      'p_pet_id': petId,
      'p_lat': lat ?? 14.5995,
      'p_lng': lng ?? 120.9842,
      'p_note': note ?? '',
    });
  }

  @override
  Future<void> markPetSafe(String petId) async {
    if (petId.startsWith('mock-')) {
      final index = _mockPets.indexWhere((p) => p.petID == petId);
      if (index != -1) {
        _mockPets[index] = _mockPets[index].copyWith(status: PetStatus.safe) as PetModel;
      }
      return;
    }

    await supabase.rpc('mark_pet_safe', params: {
      'p_pet_id': petId,
    });
  }
}
