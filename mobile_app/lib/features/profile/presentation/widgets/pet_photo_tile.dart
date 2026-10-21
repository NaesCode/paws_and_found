import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'pet_blob_painter.dart';

/// Renders the pet photo tile with an ambient blurred background
/// of the actual pet photo, and the crisp photo centered in the foreground.
class PetPhotoTile extends StatelessWidget {
  final String? photoUrl;
  final String petName;

  const PetPhotoTile({
    super.key,
    this.photoUrl,
    required this.petName,
  });

  @override
  Widget build(BuildContext context) {
    return PetBlurredBackground(
      photoUrl: photoUrl,
      child: photoUrl != null && photoUrl!.isNotEmpty
          ? Image.network(
              photoUrl!,
              fit: BoxFit.contain,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) => _fallbackPetIcon(),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                );
              },
            )
          : _fallbackPetIcon(),
    );
  }

  Widget _fallbackPetIcon() {
    return const Center(
      child: Icon(
        Icons.pets,
        size: 48,
        color: AppColors.text3,
      ),
    );
  }
}
