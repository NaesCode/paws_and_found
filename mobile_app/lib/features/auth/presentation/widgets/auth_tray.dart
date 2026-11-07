import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:paws_and_found/core/theme/app_colors.dart';
import 'package:paws_and_found/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:paws_and_found/features/auth/domain/repositories/auth_repository.dart';
import 'package:paws_and_found/shared/atoms/drag_handle.dart';
import 'package:paws_and_found/shared/atoms/google_logo.dart';
import 'package:paws_and_found/shared/atoms/paw_button.dart';
import 'package:paws_and_found/shared/atoms/paw_text_field.dart';
import 'package:paws_and_found/shared/molecules/paw_segmented_control.dart';

class AuthTray extends StatefulWidget {
  final bool isLogin;
  final ValueChanged<bool> onModeChanged;
  final AuthRepository? repository;

  const AuthTray({
    super.key,
    required this.isLogin,
    required this.onModeChanged,
    this.repository,
  });

  @override
  State<AuthTray> createState() => _AuthTrayState();
}

class _AuthTrayState extends State<AuthTray> {
  late final AuthRepository _authRepository = widget.repository ?? AuthRepositoryImpl();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _generalError;
  String? _infoMessage;
  bool _canResendEmail = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isNavigating = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void didUpdateWidget(covariant AuthTray oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLogin != widget.isLogin) {
      // Clear errors when switching between Login and Register
      setState(() {
        _nameError = null;
        _emailError = null;
        _passwordError = null;
        _confirmPasswordError = null;
        _generalError = null;
        _canResendEmail = false;
        _isGoogleLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validate() {
    bool isValid = true;
    final emailRegex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$');

    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
      _generalError = null;
      _infoMessage = null;
      _canResendEmail = false;

      // Register specific validations
      if (!widget.isLogin) {
        if (_nameController.text.trim().isEmpty) {
          _nameError = 'Full name is required';
          isValid = false;
        }
      }

      // Email validations
      final email = _emailController.text.trim();
      if (email.isEmpty) {
        _emailError = 'Email is required';
        isValid = false;
      } else if (!emailRegex.hasMatch(email)) {
        _emailError = 'Please enter a valid email address';
        isValid = false;
      }

      // Password validations
      final password = _passwordController.text;
      if (password.isEmpty) {
        _passwordError = 'Password is required';
        isValid = false;
      } else if (password.length < 6) {
        _passwordError = 'Password must be at least 6 characters';
        isValid = false;
      }

      // Confirm Password validations for Register
      if (!widget.isLogin) {
        if (_confirmPasswordController.text != password) {
          _confirmPasswordError = 'Passwords do not match';
          isValid = false;
        }
      }
    });

    return isValid;
  }

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();

    if (!_validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _generalError = null;
      _infoMessage = null;
      _canResendEmail = false;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (widget.isLogin) {
        // --- 1. Supabase Login via Repository ---
        final authResponse = await _authRepository.signInWithPassword(
          email: email,
          password: password,
        );

        if (authResponse.session == null) {
          throw const AuthException('No active session returned. Please check your credentials.');
        }

        // --- 2. Backend Handshake with Django on Login ---
        await _performBackendHandshake();
      } else {
        // --- 1. Supabase Registration via Repository ---
        final name = _nameController.text.trim();
        final authResponse = await _authRepository.signUp(
          email: email,
          password: password,
          name: name,
        );

        if (authResponse.user == null) {
          throw const AuthException('Registration failed. Please try again.');
        }

        // If email confirmation is enabled on Supabase, session is null until confirmed
        if (authResponse.session == null) {
          if (mounted) {
            setState(() {
              _infoMessage = 'Verification link sent to $email! Please verify your email, then log in below.';
              _passwordController.clear();
              _confirmPasswordController.clear();
            });
            // Automatically switch to the Login tab
            widget.onModeChanged(true);
          }
          return;
        }

        // If email confirmation is disabled, session exists immediately
        await _performBackendHandshake();
      }
    } on AuthException catch (e) {
      if (mounted) {
        String friendlyMessage = e.message;
        bool allowResend = false;

        final lowerMessage = e.message.toLowerCase();
        if (lowerMessage.contains('email not confirmed')) {
          friendlyMessage = 'Your email has not been verified yet. Please check your inbox or spam folder.';
          allowResend = true;
        } else if (lowerMessage.contains('rate limit') || e.statusCode == '429') {
          friendlyMessage = 'Too many requests. Please wait a few moments before trying again.';
        } else if (lowerMessage.contains('is invalid')) {
          friendlyMessage = 'The server rejected this email. Please use a real, deliverable email address.';
        } else if (lowerMessage.contains('user already registered')) {
          friendlyMessage = 'An account with this email already exists. Please log in.';
          widget.onModeChanged(true);
        }

        setState(() {
          _generalError = friendlyMessage;
          _canResendEmail = allowResend;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _generalError = 'An unexpected error occurred: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendConfirmationEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() {
      _isLoading = true;
      _generalError = null;
    });

    try {
      await _authRepository.resendVerificationEmail(email: email);

      if (mounted) {
        setState(() {
          _infoMessage = 'A new verification email was sent to $email. Please check your inbox.';
          _canResendEmail = false;
        });
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _generalError = 'Could not resend email: ${e.message}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _generalError = 'Failed to resend: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _performBackendHandshake() async {
    if (_isNavigating) return;
    final user = _authRepository.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _infoMessage = 'Registration complete! Please verify your email before logging in.';
        });
        widget.onModeChanged(true);
      }
      return;
    }

    _isNavigating = true;

    try {
      // 1. Admin routing check (Method 1: strictly tamper-proof app_metadata)
      if (_authRepository.isCurrentUserAdmin) {
        if (!mounted) return;
        context.go('/admin');
        return;
      }

      // 2. Standard user onboarding check
      final isFirstTimeUser = await _authRepository.checkIsFirstTimeUser(user.id);

      if (!mounted) return;

      if (isFirstTimeUser) {
        context.go('/profile/setup');
      } else {
        context.go('/home');
      }
    } catch (e) {
      if (!mounted) return;
      // Fallback: If network lookup fails, allow navigation to setup
      context.go('/profile/setup');
    } finally {
      _isNavigating = false;
    }
  }

  Future<void> _handleForgotPassword() async {
    FocusScope.of(context).unfocus();

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _ForgotPasswordSheet(
        authRepository: _authRepository,
        initialEmail: _emailController.text.trim(),
      ),
    );

    if (result == true && mounted) {
      setState(() {
        _infoMessage =
            'Password updated successfully! Please log in with your new password.';
        _passwordController.clear();
        _confirmPasswordController.clear();
      });
    }
  }
  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
      _generalError = null;
      _infoMessage = null;
      _canResendEmail = false;
    });

    try {
      final response = await _authRepository.signInWithGoogle();
      if (response == null) {
        // Canceled quietly by the user or signing key mismatch
        return;
      }

      // Perform shared post-login routing
      await _performBackendHandshake();
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _generalError = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _generalError = 'An unexpected error occurred during Google sign-in: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const DragHandle(),
              const SizedBox(height: 20),
              const Text(
                'Paws and Found',
                style: TextStyle(
                  fontFamily: 'Caveat',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkCharcoal,
                ),
              ),
              const SizedBox(height: 20),
              PawSegmentedControl(
                isFirstOptionSelected: widget.isLogin,
                firstOptionText: 'Login',
                secondOptionText: 'Register',
                onOptionChanged: widget.onModeChanged,
              ),
              const SizedBox(height: 20),

              // Informative notification banner (green/teal)
              if (_infoMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.mark_email_read_outlined, color: AppColors.primary, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _infoMessage!,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // General error banner if present
              if (_generalError != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _generalError!,
                              style: TextStyle(
                                color: Colors.red.shade800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_canResendEmail) ...[
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(left: 28.0),
                          child: GestureDetector(
                            onTap: _isLoading ? null : _resendConfirmationEmail,
                            child: const Text(
                              'Resend verification email',
                              style: TextStyle(
                                color: AppColors.accentOrange,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Form fields based on mode
              if (!widget.isLogin) ...[
                PawTextField(
                  hintText: 'Full Name',
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  errorText: _nameError,
                ),
                const SizedBox(height: 14),
              ],

              PawTextField(
                hintText: 'Email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                errorText: _emailError,
              ),
              const SizedBox(height: 14),

              PawTextField(
                hintText: 'Password',
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: widget.isLogin ? TextInputAction.done : TextInputAction.next,
                errorText: _passwordError,
                onSubmitted: widget.isLogin ? (_) => _handleSubmit() : null,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.grey.shade500,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),

              if (!widget.isLogin) ...[
                const SizedBox(height: 14),
                PawTextField(
                  hintText: 'Confirm Password',
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  errorText: _confirmPasswordError,
                  onSubmitted: (_) => _handleSubmit(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: Colors.grey.shade500,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
              ],

              // "Forgot password?" — visible only in Login mode
              if (widget.isLogin) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: (_isLoading || _isGoogleLoading) ? null : _handleForgotPassword,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: AppColors.primary,
                    ),
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: 200,
                child: PawButton(
                  text: widget.isLogin ? 'Login' : 'Register',
                  isLoading: _isLoading,
                  onPressed: _isGoogleLoading ? null : _handleSubmit,
                  color: AppColors.darkCharcoal,
                  textColor: Colors.white,
                ),
              ),

              if (widget.isLogin) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'or',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: PawButton(
                    text: 'Continue with Google',
                    isLoading: _isGoogleLoading,
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    color: Colors.white,
                    textColor: AppColors.darkCharcoal,
                    borderColor: Colors.grey.shade300,
                    leading: const GoogleLogo(size: 20),
                  ),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}


class _ForgotPasswordSheet extends StatefulWidget {
  final AuthRepository authRepository;
  final String initialEmail;

  const _ForgotPasswordSheet({
    required this.authRepository,
    required this.initialEmail,
  });

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  late final TextEditingController _emailController;
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  int _step = 0; // 0 = email, 1 = otp, 2 = new password
  late String _targetEmail;
  String? _error;
  String? _success;
  bool _isLoading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmNewPassword = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
    _targetEmail = widget.initialEmail;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    final emailRegex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (email.isEmpty || !emailRegex.hasMatch(email)) {
      setState(() {
        _error = 'Please enter a valid email address.';
        _success = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _success = null;
    });

    try {
      await widget.authRepository.resetPassword(email: email);
      if (!mounted) return;
      setState(() {
        _targetEmail = email;
        _step = 1;
        _success = 'A verification code has been sent to $email.';
        _error = null;
        _isLoading = false;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      final msg = e.message.toLowerCase();
      String friendly = e.message;
      if (msg.contains('rate limit') || e.statusCode == '429') {
        friendly = 'Too many requests. Please wait a moment before trying again.';
      } else if (msg.contains('user not found') || msg.contains('not registered')) {
        friendly = 'No account found with that email address.';
      }
      setState(() {
        _error = friendly;
        _success = null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'An unexpected error occurred. Please try again.';
        _success = null;
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length < 6) {
      setState(() {
        _error = 'Please enter the verification code.';
        _success = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _success = null;
    });

    try {
      await widget.authRepository.verifyPasswordResetOtp(
        email: _targetEmail,
        token: otp,
      );
      if (!mounted) return;
      setState(() {
        _step = 2;
        _success = 'Code verified! Please create your new password.';
        _error = null;
        _isLoading = false;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      final msg = e.message.toLowerCase();
      String friendly = e.message;
      if (msg.contains('invalid') || msg.contains('expired') || msg.contains('token')) {
        friendly = 'Invalid or expired verification code. Please check and try again.';
      } else if (msg.contains('rate limit') || e.statusCode == '429') {
        friendly = 'Too many attempts. Please wait a moment before trying again.';
      }
      setState(() {
        _error = friendly;
        _success = null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Verification failed. Please try again.';
        _success = null;
        _isLoading = false;
      });
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _success = null;
    });

    try {
      await widget.authRepository.resetPassword(email: _targetEmail);
      if (!mounted) return;
      setState(() {
        _success = 'A new verification code was sent to $_targetEmail.';
        _error = null;
        _isLoading = false;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _success = null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not resend code. Please try again later.';
        _success = null;
        _isLoading = false;
      });
    }
  }

  Future<void> _updatePassword() async {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword.isEmpty) {
      setState(() {
        _error = 'New password is required.';
        _success = null;
      });
      return;
    }

    if (newPassword.length < 6) {
      setState(() {
        _error = 'Password must be at least 6 characters.';
        _success = null;
      });
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() {
        _error = 'Passwords do not match.';
        _success = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _success = null;
    });

    try {
      await widget.authRepository.updatePassword(newPassword: newPassword);
      await widget.authRepository.signOut();

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _success = null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to update password. Please try again.';
        _success = null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header with optional step back
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _step == 0
                        ? 'Reset Password'
                        : _step == 1
                            ? 'Verification Code'
                            : 'New Password',
                    style: const TextStyle(
                      fontFamily: 'Caveat',
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkCharcoal,
                    ),
                  ),
                ),
                if (_step == 1)
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _step = 0;
                              _error = null;
                              _success = null;
                              _otpController.clear();
                            });
                          },
                    child: const Text(
                      'Change email',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _step == 0
                  ? "Enter your account email and we'll send you a verification code."
                  : _step == 1
                      ? "We sent a verification code to $_targetEmail. Enter it below to verify your identity."
                      : "Enter and confirm your new password below.",
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // Success banner
            if (_success != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.mark_email_read_outlined, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _success!,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Error banner
            if (_error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Step 0: Email Input
            if (_step == 0) ...[
              PawTextField(
                hintText: 'Email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _isLoading ? null : _sendOtp(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: PawButton(
                  text: 'Send Verification Code',
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _sendOtp,
                  color: AppColors.darkCharcoal,
                  textColor: Colors.white,
                ),
              ),
            ],

            // Step 1: OTP Input
            if (_step == 1) ...[
              PawTextField(
                hintText: 'Verification Code',
                controller: _otpController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                maxLength: 8,
                textAlign: TextAlign.center,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onSubmitted: (_) => _isLoading ? null : _verifyOtp(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: PawButton(
                  text: 'Verify Code',
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _verifyOtp,
                  color: AppColors.darkCharcoal,
                  textColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _isLoading ? null : _resendOtp,
                  child: const Text(
                    "Didn't receive code? Resend Code",
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],

            // Step 2: New Password Input
            if (_step == 2) ...[
              PawTextField(
                hintText: 'New Password',
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                textInputAction: TextInputAction.next,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNewPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.grey.shade500,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
                    });
                  },
                ),
              ),
              const SizedBox(height: 14),
              PawTextField(
                hintText: 'Confirm New Password',
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmNewPassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _isLoading ? null : _updatePassword(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmNewPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.grey.shade500,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmNewPassword = !_obscureConfirmNewPassword;
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: PawButton(
                  text: 'Update Password',
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _updatePassword,
                  color: AppColors.darkCharcoal,
                  textColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}