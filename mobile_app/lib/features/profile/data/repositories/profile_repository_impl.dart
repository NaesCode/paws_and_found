import '../../domain/entities/user_profile.dart';
import '../../domain/entities/pet.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl({ProfileRemoteDataSource? remoteDataSource})
      : remoteDataSource = remoteDataSource ?? ProfileRemoteDataSourceImpl();

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
    if (phoneNumber != null) fields['phoneNumber'] = phoneNumber;
    if (address != null) fields['address'] = address;
    if (bio != null) fields['bio'] = bio;
    if (profilePhotoURL != null) fields['profilePhotoURL'] = profilePhotoURL;

    return await remoteDataSource.updateProfile(fields);
  }

  @override
  Future<List<Pet>> getPets() async {
    return await remoteDataSource.getPets();
  }

  @override
  Future<void> reportPetMissing(String petId) async {
    return await remoteDataSource.reportPetMissing(petId);
  }

  @override
  Future<void> markPetSafe(String petId) async {
    return await remoteDataSource.markPetSafe(petId);
  }
}

