import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'pet_blob_painter.dart';

/// Renders the pet photo tile with an ambient blurred background
/// of the actual pet photo, and the crisp photo centered in the foreground.
class PetPhotoTile extends StatelessWidget {
  final String? photoUrl;
  final String petName;
  final int photoCount;
  final VoidCallback? onTap;

  const PetPhotoTile({
    super.key,
    this.photoUrl,
    required this.petName,
    this.photoCount = 1,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PetBlurredBackground(
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
          ),
          if (photoCount > 1)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.photo_library_rounded, size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '$photoCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
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
