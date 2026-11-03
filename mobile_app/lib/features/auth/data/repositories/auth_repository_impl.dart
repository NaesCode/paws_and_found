import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl({AuthRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? AuthRemoteDataSourceImpl();

  @override
  User? get currentUser => _remoteDataSource.currentUser;

  @override
  bool get isCurrentUserAdmin => _remoteDataSource.isCurrentUserAdmin;

  @override
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _remoteDataSource.signInWithPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
  }) {
    return _remoteDataSource.signUp(
      email: email,
      password: password,
      name: name,
    );
  }

  @override
  Future<void> resendVerificationEmail({
    required String email,
  }) {
    return _remoteDataSource.resendVerificationEmail(
      email: email,
    );
  }

  @override
  Future<bool> checkIsFirstTimeUser(String userId) {
    return _remoteDataSource.checkIsFirstTimeUser(userId);
  }
}
