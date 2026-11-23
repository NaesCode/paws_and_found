import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Result of evaluating a password against strong password criteria.
class PasswordValidationResult {
  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasDigit;
  final bool hasSpecialChar;

  const PasswordValidationResult({
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasDigit,
    required this.hasSpecialChar,
  });

  /// True if all 5 complexity criteria are satisfied.
  bool get isValid =>
      hasMinLength && hasUppercase && hasLowercase && hasDigit && hasSpecialChar;

  /// Count of met criteria (0 to 5) for calculating strength.
  int get score {
    int count = 0;
    if (hasMinLength) count++;
    if (hasUppercase) count++;
    if (hasLowercase) count++;
    if (hasDigit) count++;
    if (hasSpecialChar) count++;
    return count;
  }

  /// Strength label for user feedback.
  String get strengthLabel {
    if (score <= 2) return 'Weak';
    if (score <= 4) return 'Moderate';
    return 'Strong';
  }

  /// Color representing password strength.
  Color get strengthColor {
    if (score <= 2) return Colors.red.shade600;
    if (score <= 4) return Colors.amber.shade700;
    return AppColors.primary;
  }

  /// Fraction (0.0 to 1.0) for progress indicators.
  double get progressFraction => score / 5.0;

  /// Formatted error message listing missing criteria.
  String? get errorMessage {
    if (isValid) return null;
    final missing = <String>[];
    if (!hasMinLength) missing.add('at least 8 characters');
    if (!hasUppercase) missing.add('an uppercase letter (A-Z)');
    if (!hasLowercase) missing.add('a lowercase letter (a-z)');
    if (!hasDigit) missing.add('a number (0-9)');
    if (!hasSpecialChar) missing.add('a special character (!@#\$%^&*)');

    return 'Password must include ${missing.join(', ')}.';
  }
}

/// Utility for validating strong password criteria across the app.
class PasswordValidator {
  static const int minLength = 8;

  /// Evaluates [password] against all strong password criteria.
  static PasswordValidationResult validate(String password) {
    final trimmed = password.trim();
    return PasswordValidationResult(
      hasMinLength: password.length >= minLength,
      hasUppercase: RegExp(r'[A-Z]').hasMatch(trimmed),
      hasLowercase: RegExp(r'[a-z]').hasMatch(trimmed),
      hasDigit: RegExp(r'[0-9]').hasMatch(trimmed),
      hasSpecialChar: RegExp(r'[^a-zA-Z0-9]').hasMatch(trimmed),
    );
  }
}
