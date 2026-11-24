import 'package:flutter_test/flutter_test.dart';
import 'package:paws_and_found/core/utils/password_validator.dart';

void main() {
  group('PasswordValidator Unit Tests', () {
    test('rejects short passwords (< 8 characters)', () {
      final result = PasswordValidator.validate('P@1a');
      expect(result.hasMinLength, isFalse);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('at least 8 characters'));
    });

    test('rejects passwords without uppercase letter', () {
      final result = PasswordValidator.validate('paws2026!safe');
      expect(result.hasUppercase, isFalse);
      expect(result.hasLowercase, isTrue);
      expect(result.hasDigit, isTrue);
      expect(result.hasSpecialChar, isTrue);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('an uppercase letter (A-Z)'));
    });

    test('rejects passwords without lowercase letter', () {
      final result = PasswordValidator.validate('PAWS2026!SAFE');
      expect(result.hasUppercase, isTrue);
      expect(result.hasLowercase, isFalse);
      expect(result.hasDigit, isTrue);
      expect(result.hasSpecialChar, isTrue);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('a lowercase letter (a-z)'));
    });

    test('rejects passwords without numbers', () {
      final result = PasswordValidator.validate('PawsAndFound!');
      expect(result.hasUppercase, isTrue);
      expect(result.hasLowercase, isTrue);
      expect(result.hasDigit, isFalse);
      expect(result.hasSpecialChar, isTrue);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('a number (0-9)'));
    });

    test('rejects passwords without special characters', () {
      final result = PasswordValidator.validate('PawsAndFound2026');
      expect(result.hasUppercase, isTrue);
      expect(result.hasLowercase, isTrue);
      expect(result.hasDigit, isTrue);
      expect(result.hasSpecialChar, isFalse);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('a special character (!@#\$%^&*)'));
    });

    test('accepts strong password meeting all 5 criteria', () {
      final result = PasswordValidator.validate('Paws2026@Found');
      expect(result.hasMinLength, isTrue);
      expect(result.hasUppercase, isTrue);
      expect(result.hasLowercase, isTrue);
      expect(result.hasDigit, isTrue);
      expect(result.hasSpecialChar, isTrue);
      expect(result.isValid, isTrue);
      expect(result.score, 5);
      expect(result.strengthLabel, 'Strong');
      expect(result.errorMessage, isNull);
    });

    test('correctly calculates score and strength labels', () {
      final weak = PasswordValidator.validate('pass');
      expect(weak.score, lessThanOrEqualTo(2));
      expect(weak.strengthLabel, 'Weak');

      final moderate = PasswordValidator.validate('Password2026');
      expect(moderate.score, 4); // minLength, upper, lower, digit (missing special)
      expect(moderate.strengthLabel, 'Moderate');
    });
  });
}
