import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:paws_and_found/features/auth/domain/repositories/auth_repository.dart';
import 'package:paws_and_found/features/auth/presentation/pages/login_page.dart';
import 'package:paws_and_found/shared/atoms/app_logo_placeholder.dart';
import 'package:paws_and_found/shared/molecules/app_brand_title_placeholder.dart';

class MockAuthRepository implements AuthRepository {
  @override
  User? get currentUser => null;

  @override
  bool get isCurrentUserAdmin => false;

  @override
  Future<bool> checkIsFirstTimeUser(String userId) async => false;

  @override
  Future<AuthResponse?> signInWithGoogle() async => null;

  @override
  Future<AuthResponse> signInWithPassword({required String email, required String password}) async {
    return AuthResponse();
  }

  @override
  Future<AuthResponse> signUp({required String email, required String password, required String name}) async {
    return AuthResponse();
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> resetPassword({required String email}) async {}

  @override
  Future<void> verifyPasswordResetOtp({required String email, required String token}) async {}

  @override
  Future<void> updatePassword({required String newPassword}) async {}

  @override
  Future<void> resendVerificationEmail({required String email}) async {}
}

void main() {
  group('LoginPage Branding Overhaul & UI Tests', () {
    testWidgets('renders brand title placeholder, logo emblem, and auth tray', (tester) async {
      final mockRepo = MockAuthRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(authRepository: mockRepo),
        ),
      );
      await tester.pumpAndSettle();

      // Brand placeholder elements in hero header
      expect(find.byType(AppBrandTitlePlaceholder), findsOneWidget);
      expect(find.byType(AppLogoPlaceholder), findsOneWidget);
      expect(find.text('Paws and Found'), findsWidgets);
      expect(find.text('Community Lost & Found Animal Recovery'), findsOneWidget);
      expect(find.text('LOGO PLACEHOLDER'), findsOneWidget);

      // Auth Tray default is Login mode
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Enter your credentials to continue'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets('switching to Register mode updates tray header to Create Account', (tester) async {
      final mockRepo = MockAuthRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(authRepository: mockRepo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome Back'), findsOneWidget);

      // Tap Register tab
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Join the community to help pets find home'), findsOneWidget);
      // Google sign-in is hidden in Register mode
      expect(find.text('Continue with Google'), findsNothing);

      // Tap back to Login
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
    });
  });
}
