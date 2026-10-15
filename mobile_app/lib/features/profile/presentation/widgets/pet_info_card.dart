import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/pet.dart';

/// Renders the information card for a pet:
/// - Status banner flush to top edge (SAFE in Teal / MISSING in Maroon)
/// - Name, Specie, Description label and clamp-to-5-lines description text
/// - Border 1.5 black, background2 fill
class PetInfoCard extends StatelessWidget {
  final Pet pet;

  const PetInfoCard({
    super.key,
    required this.pet,
  });

  @override
  Widget build(BuildContext context) {
    final isSafe = pet.status == PetStatus.safe;
    final statusColor = isSafe ? AppColors.primary : AppColors.contrast2;
    final statusText = isSafe ? 'S A F E' : 'M I S S I N G';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background2,
        border: Border.all(
          color: AppColors.text2,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Flush status banner at top
          Container(
            padding: const EdgeInsets.symmetric(vertical: 2.5),
            color: statusColor,
            child: Text(
              statusText,
              textAlign: TextAlign.center,
              style: AppTypography.statusBanner,
            ),
          ),

          // Card content padding
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: AppTypography.petName,
                        children: [
                          const TextSpan(text: 'Name: '),
                          TextSpan(
                            text: pet.name,
                            style: AppTypography.petName.copyWith(fontWeight: FontWeight.w400),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: AppTypography.petName,
                        children: [
                          const TextSpan(text: 'Specie: '),
                          TextSpan(
                            text: pet.displaySpecies,
                            style: AppTypography.petName.copyWith(fontWeight: FontWeight.w400),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Description:',
                      style: TextStyle(
                        fontFamily: 'Ek Mukta',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Text(
                        (pet.description != null && pet.description!.trim().isNotEmpty)
                            ? pet.description!
                            : 'No description provided.',
                        style: AppTypography.petDescription,
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

