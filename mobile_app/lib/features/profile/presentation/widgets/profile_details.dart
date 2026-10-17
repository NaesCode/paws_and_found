import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/atoms/paw_pill_button.dart';
import '../../domain/entities/user_profile.dart';

/// Renders the details block beneath the identity block:
/// Divider (60% width), Address, Contact, Registered Pets count, and the "+ Add pet" pill.
class ProfileDetails extends StatelessWidget {
  final UserProfile user;
  final int registeredPetsCount;
  final VoidCallback? onAddPetPressed;

  const ProfileDetails({
    super.key,
    required this.user,
    required this.registeredPetsCount,
    this.onAddPetPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background1,
      padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thin horizontal divider spanning ~60% width of the card
          FractionallySizedBox(
            widthFactor: 0.60,
            alignment: Alignment.centerLeft,
            child: Container(
              height: 1.0,
              color: AppColors.background2,
              margin: const EdgeInsets.only(bottom: 12.0),
            ),
          ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Left text column (Address, Contact, Registered Pets)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Address: ${user.address != null && user.address!.trim().isNotEmpty ? user.address! : "Not set"}',
                      style: AppTypography.detailText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Contact: ${user.phoneNumber != null && user.phoneNumber!.trim().isNotEmpty ? user.phoneNumber! : "Not set"}',
                      style: AppTypography.detailText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Registered Pets: $registeredPetsCount',
                      style: AppTypography.detailText,
                    ),
                  ],
                ),
              ),

              // Right: "+ Add pet" pill button (shown once pets exist; empty state has its own CTA)
              if (registeredPetsCount > 0)
                Semantics(
                  button: true,
                  label: 'Add pet',
                  child: PawPillButton.primary(
                    onPressed: onAddPetPressed,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    leadingIcon: const Text(
                      '+',
                      style: TextStyle(
                        color: AppColors.text1,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    trailingIcon: const Icon(
                      Icons.pets,
                      size: 11,
                      color: AppColors.text1,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

