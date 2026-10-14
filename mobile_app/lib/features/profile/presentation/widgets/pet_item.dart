import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/atoms/paw_pill_button.dart';
import '../../domain/entities/pet.dart';
import 'pet_photo_tile.dart';
import 'pet_info_card.dart';

/// Renders a single pet card item containing:
/// - A right-aligned action pill ("Report Missing!" or "Mark as Safe")
/// - A row of [photo tile] [8 gap] [info card] with height ~158.
class PetItem extends StatelessWidget {
  final Pet pet;
  final VoidCallback? onStatusActionPressed;
  final VoidCallback? onTap;

  const PetItem({
    super.key,
    required this.pet,
    this.onStatusActionPressed,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSafe = pet.status == PetStatus.safe;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Right-aligned status action pill directly above card
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: isSafe
                  ? PawPillButton.danger(
                      text: 'Report Missing!',
                      onPressed: onStatusActionPressed,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      trailingIcon: const Icon(
                        Icons.pets,
                        size: 11,
                        color: AppColors.text1,
                      ),
                    )
                  : PawPillButton.primary(
                      text: 'Mark as Safe',
                      onPressed: onStatusActionPressed,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      trailingIcon: const Icon(
                        Icons.check_circle_outline,
                        size: 12,
                        color: AppColors.text1,
                      ),
                    ),
            ),
          ),

          // Main Pet Row: Photo Tile (~48%) + Gap (8) + Info Card (~50%)
          GestureDetector(
            onTap: onTap,
            child: SizedBox(
              height: 158,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 48,
                    child: PetPhotoTile(
                      photoUrl: pet.photoURLs.isNotEmpty ? pet.photoURLs.first : null,
                      petName: pet.name,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 52,
                    child: PetInfoCard(pet: pet),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

