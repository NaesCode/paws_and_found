import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/password_validator.dart';

/// Reusable molecule displaying a real-time checklist and strength indicator
/// for strong password requirements.
class PasswordRequirementsView extends StatelessWidget {
  final PasswordValidationResult result;
  final bool isVisible;

  const PasswordRequirementsView({
    super.key,
    required this.result,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Strength bar & label
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: result.progressFraction,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(result.strengthColor),
                    minHeight: 5,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                result.strengthLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: result.strengthColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Checklist items
          _buildCheckItem(
            isMet: result.hasMinLength,
            label: 'At least 8 characters',
          ),
          const SizedBox(height: 4),
          _buildCheckItem(
            isMet: result.hasUppercase,
            label: 'At least 1 uppercase letter (A-Z)',
          ),
          const SizedBox(height: 4),
          _buildCheckItem(
            isMet: result.hasLowercase,
            label: 'At least 1 lowercase letter (a-z)',
          ),
          const SizedBox(height: 4),
          _buildCheckItem(
            isMet: result.hasDigit,
            label: 'At least 1 number (0-9)',
          ),
          const SizedBox(height: 4),
          _buildCheckItem(
            isMet: result.hasSpecialChar,
            label: 'At least 1 special character (!@#\$%^&*)',
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem({
    required bool isMet,
    required String label,
  }) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          size: 15,
          color: isMet ? AppColors.primary : AppColors.text3,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontFamily: 'Nunito Sans',
            color: isMet ? AppColors.darkCharcoal : AppColors.text3,
            fontWeight: isMet ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
