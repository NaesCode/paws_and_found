import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'pet_blob_painter.dart';

/// Renders the pet photo tile with a white square background,
/// an organic orange blob, and the pet cutout / photo placed on top.
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
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background1,
      ),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Orange organic blob backdrop (~75% of tile size)
          Positioned(
            bottom: 4,
            left: 10,
            right: 10,
            top: 24,
            child: CustomPaint(
              painter: const PetBlobPainter(),
            ),
          ),

          // Pet photo positioned on top, bottom-aligned
          if (photoUrl != null && photoUrl!.isNotEmpty)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                child: Image.network(
                  photoUrl!,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                  errorBuilder: (context, error, stackTrace) => _fallbackPetIcon(),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                    );
                  },
                ),
              ),
            )
          else
            _fallbackPetIcon(),
        ],
      ),
    );
  }

  Widget _fallbackPetIcon() {
    return const Center(
      child: Icon(
        Icons.pets,
        size: 54,
        color: Colors.white,
      ),
    );
  }
}

