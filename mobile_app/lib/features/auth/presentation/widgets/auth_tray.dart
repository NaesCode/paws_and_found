import 'dart:convert';
import 'package:flutter/material.dart';
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
      } else {
        // --- 1. Supabase Registration ---
        // CRITICAL: Must pass name in user_metadata so Django can populate User.name
        final name = _nameController.text.trim();
        final authResponse = await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
          data: {'name': name},
        );

        if (authResponse.user == null) {
          throw const AuthException('Registration failed. Please try again.');
        }
      }

      // --- 2. Backend Handshake with Django ---
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
          _generalError = 'An error occurred: $e';
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
      // If email confirmation is required on Supabase, session is null until confirmed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Account created! If email confirmation is required, please check your inbox before logging in.',
            ),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 4),
          ),
        );
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
        final userName = userData['name'] ?? 'User';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome, $userName! Connected to backend successfully.'),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 4),
          ),
        );
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
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
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
                  child: Row(
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

