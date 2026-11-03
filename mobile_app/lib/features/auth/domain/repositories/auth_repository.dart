import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
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

  /// Validates admin status strictly from tamper-proof JWT app_metadata.
  bool get isCurrentUserAdmin;

  User? get currentUser;
}
