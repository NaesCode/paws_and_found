import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  });

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
  });

  Future<void> resendVerificationEmail({
    required String email,
  });

  Future<bool> checkIsFirstTimeUser(String userId);

  /// Synchronous check from tamper-proof JWT app_metadata (Method 1).
  bool get isCurrentUserAdmin;

  User? get currentUser;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient _supabase;

  AuthRemoteDataSourceImpl({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  @override
  User? get currentUser => _supabase.auth.currentUser;

  @override
  bool get isCurrentUserAdmin {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;
    final metadata = user.appMetadata;
    return metadata['is_admin'] == true ||
        metadata['role'] == 'admin' ||
        metadata['role'] == 'ADMIN';
  }

  @override
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _supabase.auth.signInWithPassword(
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
    return _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );
  }

  @override
  Future<void> resendVerificationEmail({
    required String email,
  }) {
    return _supabase.auth.resend(
      type: OtpType.signup,
      email: email,
    );
  }

  @override
  Future<bool> checkIsFirstTimeUser(String userId) async {
    final profile = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    final userName = (profile?['name'] as String?)?.trim() ?? '';
    final phoneNumber = (profile?['phone_number'] as String?)?.trim();
    final address = (profile?['address'] as String?)?.trim();

    return userName.isEmpty ||
        phoneNumber == null ||
        phoneNumber.isEmpty ||
        address == null ||
        address.isEmpty;
  }
}
