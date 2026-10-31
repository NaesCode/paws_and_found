import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/pet.dart';
import 'pet_item.dart';

/// The "Paws Profile" section displaying registered pet cards.
///
/// Encapsulates the designated gray container from the UI specification:
/// - Section header "Paws Profile"
/// - List of [PetItem] cards reflecting current database rows
/// - Empty state when no pets exist with an action to add one
/// - Loading state indicator
class PawsProfileSection extends StatelessWidget {
  final List<Pet> pets;
  final bool isLoading;
  final ValueChanged<Pet> onStatusToggle;
  final ValueChanged<Pet>? onDeletePet;
  final ValueChanged<Pet>? onPetTap;
  final VoidCallback? onAddPetPressed;

  const PawsProfileSection({
    super.key,
    required this.pets,
    this.isLoading = false,
    required this.onStatusToggle,
    this.onDeletePet,
    this.onPetTap,
    this.onAddPetPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background2,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Title Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Paws Profile',
                style: AppTypography.sectionTitle,
              ),
              if (pets.isNotEmpty)
                Text(
                  '${pets.length} ${pets.length == 1 ? 'pet' : 'pets'}',
                  style: const TextStyle(
                    fontFamily: 'Ek Mukta',
                    fontSize: 13,
                    color: AppColors.text3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Loading indicator
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36.0),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          // Empty State
          else if (pets.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.pets, size: 32, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Pets Registered Yet',
                    style: TextStyle(
                      fontFamily: 'Nunito Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkCharcoal,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Register your pets so you can quickly report them missing or keep their profile handy.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Ek Mukta',
                      fontSize: 13,
                      color: AppColors.text3,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (onAddPetPressed != null)
                    ElevatedButton.icon(
                      onPressed: onAddPetPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text(
                        'Add Pet',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            )
          // Pets List
          else
            ...pets.map(
              (pet) => PetItem(
                pet: pet,
                onStatusActionPressed: () => onStatusToggle(pet),
                onDeletePressed: onDeletePet != null ? () => onDeletePet!(pet) : null,
                onTap: () => onPetTap?.call(pet),
              ),
            ),
        ],
      ),
    );
  }
}

