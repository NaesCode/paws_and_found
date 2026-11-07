import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:paws_and_found/core/constants/api_constants.dart';

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

  /// Authenticates using native Google Sign-In and Supabase OAuthProvider.google ID token.
  /// Returns [AuthResponse] on success, or null if the user canceled the account picker.
  Future<AuthResponse?> signInWithGoogle();

  /// Clears both Google on-device sign-in and Supabase session.
  Future<void> signOut();

  /// Sends a 6-digit OTP to [email] for password recovery (no redirect link).
  Future<void> resetPassword({
    required String email,
  });

  /// Verifies the recovery OTP and establishes a recovery session.
  Future<void> verifyPasswordResetOtp({
    required String email,
    required String token,
  });

  /// Updates the current user's password (requires an active recovery session).
  Future<void> updatePassword({
    required String newPassword,
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
  final GoogleSignIn _googleSignIn;
  static bool _isGoogleSignInInitialized = false;

  AuthRemoteDataSourceImpl({
    SupabaseClient? client,
    GoogleSignIn? googleSignIn,
  })  : _supabase = client ?? Supabase.instance.client,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_isGoogleSignInInitialized) return;
    final webClientId = ApiConstants.googleWebClientId;
    final iosClientId = ApiConstants.googleIosClientId;
    if (webClientId.isEmpty) {
      debugPrint('[AuthRemoteDataSource] Warning: GOOGLE_WEB_CLIENT_ID not set in environment.');
    }
    await _googleSignIn.initialize(
      serverClientId: webClientId.isNotEmpty ? webClientId : null,
      clientId: (!kIsWeb && Platform.isIOS && iosClientId.isNotEmpty) ? iosClientId : null,
    );
    _isGoogleSignInInitialized = true;
  }

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
  Future<AuthResponse?> signInWithGoogle() async {
    await _ensureGoogleSignInInitialized();

    try {
      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AuthException('No ID token received from Google.');
      }

      String? accessToken;
      try {
        final authorization = await account.authorizationClient.authorizationForScopes([]);
        accessToken = authorization?.accessToken;
      } catch (e) {
        debugPrint('[AuthRemoteDataSource] Note: Access token retrieval returned null or failed: $e');
      }

      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      return response;
    } on GoogleSignInException catch (e) {
      debugPrint('[AuthRemoteDataSource] GoogleSignInException: code=${e.code}, description=${e.description}');
      // On Android, wrong package name or SHA-1 fingerprint can also report as canceled
      if (e.code == GoogleSignInExceptionCode.canceled) {
        debugPrint('[AuthRemoteDataSource] Google Sign-In was canceled by user or signing key mismatch.');
        return null;
      }
      throw AuthException('Google Sign-In failed: ${e.description ?? e.code.name}');
    } catch (e) {
      if (e is AuthException) rethrow;
      debugPrint('[AuthRemoteDataSource] Unexpected Google Sign-In error: $e');
      throw AuthException('Failed to sign in with Google: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('[AuthRemoteDataSource] Google signOut notice: $e');
    }
    await _supabase.auth.signOut();
  }

  @override
  Future<void> resetPassword({
    required String email,
  }) {
    // No redirectTo — Supabase will send a 6-digit OTP to the email instead
    // of a magic link. The user enters the OTP in-app.
    return _supabase.auth.resetPasswordForEmail(email);
  }

  @override
  Future<void> verifyPasswordResetOtp({
    required String email,
    required String token,
  }) async {
    await _supabase.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.recovery,
    );
  }

  @override
  Future<void> updatePassword({
    required String newPassword,
  }) {
    return _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
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
