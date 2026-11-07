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

  /// Authenticates using native Google Sign-In and Supabase OAuthProvider.google ID token.
  /// Returns [AuthResponse] on success, or null if the user canceled the account picker.
  Future<AuthResponse?> signInWithGoogle();

  /// Clears both Google on-device sign-in and Supabase session.
  Future<void> signOut();

  /// Sends a 6-digit OTP to [email] for password recovery (no redirect link).
  /// Throws [AuthException] on failure (rate limit, invalid email, etc.)
  Future<void> resetPassword({
    required String email,
  });

  /// Verifies the 6-digit OTP the user received and returns a recovery session.
  /// Throws [AuthException] if the token is wrong or expired.
  Future<void> verifyPasswordResetOtp({
    required String email,
    required String token,
  });

  /// Updates the authenticated user's password. Must be called after a
  /// successful [verifyPasswordResetOtp] which establishes a recovery session.
  Future<void> updatePassword({
    required String newPassword,
  });

  Future<void> resendVerificationEmail({
    required String email,
  });

  Future<bool> checkIsFirstTimeUser(String userId);

  /// Validates admin status strictly from tamper-proof JWT app_metadata.
  bool get isCurrentUserAdmin;

  User? get currentUser;
}
