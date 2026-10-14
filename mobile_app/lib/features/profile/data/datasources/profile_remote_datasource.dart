import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/user_profile_model.dart';
import '../models/pet_model.dart';
import '../../domain/entities/pet.dart';

abstract class ProfileRemoteDataSource {
  Future<UserProfileModel> getProfile();
  Future<UserProfileModel> updateProfile(Map<String, dynamic> fields);
  Future<List<PetModel>> getPets();
  Future<void> reportPetMissing(String petId);
  Future<void> markPetSafe(String petId);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final http.Client client;

  ProfileRemoteDataSourceImpl({http.Client? client}) : client = client ?? http.Client();

  String? get _authToken => Supabase.instance.client.auth.currentSession?.accessToken;

  Map<String, String> get _headers => {
        'Authorization': 'Bearer ${_authToken ?? ''}',
        'Content-Type': 'application/json',
      };

  @override
  Future<UserProfileModel> getProfile() async {
    final response = await client.get(
      Uri.parse(ApiConstants.meEndpoint),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return UserProfileModel.fromJson(json);
    } else {
      throw Exception('Failed to load profile (${response.statusCode}): ${response.body}');
    }
  }

  @override
  Future<UserProfileModel> updateProfile(Map<String, dynamic> fields) async {
    final response = await client.patch(
      Uri.parse(ApiConstants.meEndpoint),
      headers: _headers,
      body: jsonEncode(fields),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return UserProfileModel.fromJson(json);
    } else {
      throw Exception('Failed to update profile (${response.statusCode}): ${response.body}');
    }
  }

  // --- Mock pets per UI Specification Section 6 ---
  // In-memory list simulating pets until backend pet endpoints are built.
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
    // Simulate brief network delay
    await Future.delayed(const Duration(milliseconds: 150));
    return List.from(_mockPets);
  }

  @override
  Future<void> reportPetMissing(String petId) async {
    final index = _mockPets.indexWhere((p) => p.petID == petId);
    if (index != -1) {
      _mockPets[index] = _mockPets[index].copyWith(status: PetStatus.missing) as PetModel;
    }
  }

  @override
  Future<void> markPetSafe(String petId) async {
    final index = _mockPets.indexWhere((p) => p.petID == petId);
    if (index != -1) {
      _mockPets[index] = _mockPets[index].copyWith(status: PetStatus.safe) as PetModel;
    }
  }
}

