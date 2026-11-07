import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:paws_and_found/features/auth/domain/repositories/auth_repository.dart';
import 'package:paws_and_found/features/auth/presentation/widgets/auth_tray.dart';
import 'package:paws_and_found/shared/atoms/google_logo.dart';
import 'package:paws_and_found/shared/atoms/paw_button.dart';

class MockAuthRepository implements AuthRepository {
  bool signInWithGoogleCalled = false;
  bool shouldCancelGoogle = false;
  bool shouldThrowGoogle = false;
  bool shouldThrowResetPassword = false;
  bool signOutCalled = false;
  bool firstTimeUser = false;
  bool adminUser = false;
  User? testUser;

  @override
  User? get currentUser => testUser;

  @override
  bool get isCurrentUserAdmin => adminUser;

  @override
  Future<bool> checkIsFirstTimeUser(String userId) async => firstTimeUser;

  @override
  Future<AuthResponse?> signInWithGoogle() async {
    signInWithGoogleCalled = true;
    if (shouldThrowGoogle) {
      throw const AuthException('Simulated Google Sign-In Error');
    }
    if (shouldCancelGoogle) {
      return null;
    }
    return AuthResponse(
      session: Session(
        accessToken: 'mock_token',
        tokenType: 'bearer',
        user: const User(
          id: 'google-user-123',
          appMetadata: {},
          userMetadata: {'name': 'Google Tester'},
          aud: 'authenticated',
          createdAt: '2026-11-07',
        ),
      ),
      user: const User(
        id: 'google-user-123',
        appMetadata: {},
        userMetadata: {'name': 'Google Tester'},
        aud: 'authenticated',
        createdAt: '2026-11-07',
      ),
    );
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
  }

  @override
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    return AuthResponse();
  }

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    return AuthResponse();
  }

  @override
  Future<void> resendVerificationEmail({required String email}) async {}

  @override
  Future<void> resetPassword({required String email}) async {
    if (shouldThrowResetPassword) {
      throw const AuthException('Rate limit exceeded. Please wait before trying again.');
    }
  }

  @override
  Future<void> verifyPasswordResetOtp({
    required String email,
    required String token,
  }) async {
    if (token != '123456' && token != '12345678') {
      throw const AuthException('Invalid OTP code.');
    }
  }

  @override
  Future<void> updatePassword({
    required String newPassword,
  }) async {}
}

void main() {
  group('Google Sign-In & AuthTray UI Tests', () {
    testWidgets('renders "Continue with Google" and "or" divider when in Login mode', (tester) async {
      final mockRepo = MockAuthRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthTray(
              isLogin: true,
              onModeChanged: (_) {},
              repository: mockRepo,
            ),
          ),
        ),
      );

      // Verify "or" divider exists
      expect(find.text('or'), findsOneWidget);

      // Verify "Continue with Google" button exists with GoogleLogo atom
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.byType(GoogleLogo), findsOneWidget);
    });

    testWidgets('does not render "Continue with Google" button in Register mode', (tester) async {
      final mockRepo = MockAuthRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthTray(
              isLogin: false,
              onModeChanged: (_) {},
              repository: mockRepo,
            ),
          ),
        ),
      );

      expect(find.text('or'), findsNothing);
      expect(find.text('Continue with Google'), findsNothing);
    });

    testWidgets('tapping "Continue with Google" triggers signInWithGoogle and handles quiet cancellation', (tester) async {
      final mockRepo = MockAuthRepository()..shouldCancelGoogle = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthTray(
              isLogin: true,
              onModeChanged: (_) {},
              repository: mockRepo,
            ),
          ),
        ),
      );

      final googleButton = find.widgetWithText(PawButton, 'Continue with Google');
      expect(googleButton, findsOneWidget);

      await tester.tap(googleButton);
      await tester.pump();

      expect(mockRepo.signInWithGoogleCalled, isTrue);
      // Quiet cancel does not surface an error message
      expect(find.textContaining('Error'), findsNothing);
    });

    testWidgets('surfaces error message when Google Sign-In throws AuthException', (tester) async {
      final mockRepo = MockAuthRepository()..shouldThrowGoogle = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthTray(
              isLogin: true,
              onModeChanged: (_) {},
              repository: mockRepo,
            ),
          ),
        ),
      );

      final googleButton = find.widgetWithText(PawButton, 'Continue with Google');
      await tester.tap(googleButton);
      await tester.pump();

      expect(find.text('Simulated Google Sign-In Error'), findsOneWidget);
    });
  });

  group('Forgot Password UI Tests', () {
    testWidgets('renders "Forgot password?" button only in Login mode', (tester) async {
      final mockRepo = MockAuthRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthTray(
              isLogin: true,
              onModeChanged: (_) {},
              repository: mockRepo,
            ),
          ),
        ),
      );

      expect(find.text('Forgot password?'), findsOneWidget);
    });

    testWidgets('does not render "Forgot password?" in Register mode', (tester) async {
      final mockRepo = MockAuthRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthTray(
              isLogin: false,
              onModeChanged: (_) {},
              repository: mockRepo,
            ),
          ),
        ),
      );

      expect(find.text('Forgot password?'), findsNothing);
    });

    testWidgets('tapping "Forgot password?" opens Reset Password bottom sheet', (tester) async {
      final mockRepo = MockAuthRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthTray(
              isLogin: true,
              onModeChanged: (_) {},
              repository: mockRepo,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();

      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Send Verification Code'), findsOneWidget);
    });

    testWidgets('completes full OTP verification and password update flow', (tester) async {
      final mockRepo = MockAuthRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthTray(
              isLogin: true,
              onModeChanged: (_) {},
              repository: mockRepo,
            ),
          ),
        ),
      );

      // Open sheet
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();

      // Step 0: Enter email and submit
      final emailField = find.widgetWithText(TextField, 'Email').last;
      await tester.enterText(emailField, 'user@example.com');
      await tester.tap(find.text('Send Verification Code'));
      await tester.pumpAndSettle();

      // Should transition to Step 1 (OTP)
      expect(find.text('Verification Code'), findsWidgets);
      expect(find.text('Verify Code'), findsOneWidget);

      // Step 1: Enter OTP and submit (supports both 6 and 8 digit codes)
      final otpField = find.widgetWithText(TextField, 'Verification Code');
      await tester.enterText(otpField, '12345678');
      await tester.tap(find.text('Verify Code'));
      await tester.pumpAndSettle();

      // Should transition to Step 2 (New Password)
      expect(find.text('New Password'), findsWidgets);
      expect(find.text('Update Password'), findsOneWidget);

      // Step 2: Enter new password and confirm
      final newPassField = find.widgetWithText(TextField, 'New Password');
      final confirmPassField = find.widgetWithText(TextField, 'Confirm New Password');
      await tester.enterText(newPassField, 'newsecret123');
      await tester.enterText(confirmPassField, 'newsecret123');
      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();

      // Sheet should close and success banner appear on login screen
      expect(find.text('Reset Password'), findsNothing);
      expect(find.textContaining('Password updated successfully'), findsOneWidget);
    });
  });
}
