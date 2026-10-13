import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:paws_and_found/core/constants/api_constants.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';
import 'package:paws_and_found/shared/atoms/drag_handle.dart';
import 'package:paws_and_found/shared/atoms/paw_button.dart';
import 'package:paws_and_found/shared/atoms/paw_text_field.dart';
import 'package:paws_and_found/shared/molecules/paw_segmented_control.dart';

class AuthTray extends StatefulWidget {
  final bool isLogin;
  final ValueChanged<bool> onModeChanged;

  const AuthTray({
    super.key,
    required this.isLogin,
    required this.onModeChanged,
  });

  @override
  State<AuthTray> createState() => _AuthTrayState();
}

class _AuthTrayState extends State<AuthTray> {
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
        // --- 1. Supabase Login ---
        final authResponse = await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (authResponse.session == null) {
          throw const AuthException('No active session returned. Please check your credentials.');
        }

        // --- 2. Backend Handshake with Django on Login ---
        await _performBackendHandshake();
      } else {
        // --- 1. Supabase Registration ---
        final name = _nameController.text.trim();
        final authResponse = await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
          data: {'name': name},
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
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: email,
      );

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
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken;

    if (token == null) {
      if (mounted) {
        setState(() {
          _infoMessage = 'Registration complete! Please verify your email before logging in.';
        });
        widget.onModeChanged(true);
      }
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConstants.meEndpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 8));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body) as Map<String, dynamic>;
        final userName = (userData['name'] as String?) ?? '';
        final phoneNumber = userData['phoneNumber'];

        // Determine routing based on profile completeness.
        // A first-time user (auto-created by Django on first login) will have
        // an empty name or no phone number — send them to profile setup.
        // A returning user with a full profile goes straight to home.
        final bool isFirstTimeUser = userName.trim().isEmpty || phoneNumber == null;

        if (!mounted) return;

        if (isFirstTimeUser) {
          context.go('/profile/setup');
        } else {
          context.go('/home');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Supabase authenticated, but Django returned ${response.statusCode}: ${response.body}'),
            backgroundColor: AppColors.accentOrange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Authenticated with Supabase, but could not reach Django: $e'),
          backgroundColor: AppColors.accentOrange,
          duration: const Duration(seconds: 4),
        ),
      );
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
                obscureText: true,
                textInputAction: widget.isLogin ? TextInputAction.done : TextInputAction.next,
                errorText: _passwordError,
                onSubmitted: widget.isLogin ? (_) => _handleSubmit() : null,
              ),

              if (!widget.isLogin) ...[
                const SizedBox(height: 14),
                PawTextField(
                  hintText: 'Confirm Password',
                  controller: _confirmPasswordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  errorText: _confirmPasswordError,
                  onSubmitted: (_) => _handleSubmit(),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: 200,
                child: PawButton(
                  text: widget.isLogin ? 'Login' : 'Register',
                  isLoading: _isLoading,
                  onPressed: _handleSubmit,
                  color: AppColors.darkCharcoal,
                  textColor: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
