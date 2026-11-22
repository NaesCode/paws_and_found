import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/pet.dart';

/// Modal dialog that allows pet owners to view and swipe through all registered
/// photos of their pet, with zoom capabilities and status information.
class PetPhotoGalleryModal extends StatefulWidget {
  final Pet pet;
  final VoidCallback? onEditPressed;

  const PetPhotoGalleryModal({
    super.key,
    required this.pet,
    this.onEditPressed,
  });

  /// Static helper to display the gallery dialog.
  static Future<void> show({
    required BuildContext context,
    required Pet pet,
    VoidCallback? onEditPressed,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => PetPhotoGalleryModal(
        pet: pet,
        onEditPressed: onEditPressed,
      ),
    );
  }

  @override
  State<PetPhotoGalleryModal> createState() => _PetPhotoGalleryModalState();
}

class _PetPhotoGalleryModalState extends State<PetPhotoGalleryModal> {
  late final PageController _pageController;
  int _currentPage = 0;

  List<String> get _photos => widget.pet.photoURLs;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;
    final isMissing = pet.status == PetStatus.missing;
    final totalPhotos = _photos.length;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
          maxWidth: 420,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header with Pet Info & Close
            Padding(
              padding: const EdgeInsets.fromLTRB(18.0, 16.0, 12.0, 12.0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.pets, size: 22, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                pet.name,
                                style: const TextStyle(
                                  fontFamily: 'Nunito Sans',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.darkCharcoal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isMissing
                                    ? AppColors.statusMissing.withValues(alpha: 0.12)
                                    : AppColors.statusSafe.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isMissing ? AppColors.statusMissing : AppColors.statusSafe,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                isMissing ? 'MISSING' : 'SAFE',
                                style: TextStyle(
                                  fontFamily: 'Nunito Sans',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: isMissing ? AppColors.statusMissing : AppColors.statusSafe,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${pet.species}${(pet.breed?.isNotEmpty ?? false) ? ' • ${pet.breed}' : ''}',
                          style: const TextStyle(
                            fontFamily: 'Ek Mukta',
                            fontSize: 12.5,
                            color: AppColors.text3,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.darkSlate),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.divider),

            // 2. Photo Carousel View
            Expanded(
              child: totalPhotos == 0
                  ? _buildEmptyPhotoState()
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          itemCount: totalPhotos,
                          onPageChanged: (index) {
                            setState(() => _currentPage = index);
                          },
                          itemBuilder: (context, index) {
                            final photoUrl = _photos[index];
                            return InteractiveViewer(
                              minScale: 1.0,
                              maxScale: 4.0,
                              child: Container(
                                color: const Color(0xFF0F172A),
                                child: Image.network(
                                  photoUrl,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildErrorPhotoState(),
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(color: AppColors.primary),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),

                        // Floating Photo Counter Badge
                        if (totalPhotos > 1)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.photo_library_outlined, size: 14, color: Colors.white),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${_currentPage + 1} of $totalPhotos',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Left Arrow Button (if multiple photos)
                        if (totalPhotos > 1 && _currentPage > 0)
                          Positioned(
                            left: 8,
                            child: IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black.withValues(alpha: 0.5),
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.chevron_left_rounded, size: 28),
                              onPressed: () {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                );
                              },
                            ),
                          ),

                        // Right Arrow Button (if multiple photos)
                        if (totalPhotos > 1 && _currentPage < totalPhotos - 1)
                          Positioned(
                            right: 8,
                            child: IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black.withValues(alpha: 0.5),
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.chevron_right_rounded, size: 28),
                              onPressed: () {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                );
                              },
                            ),
                          ),
                      ],
                    ),
            ),

            // 3. Dot Indicators (if multiple photos)
            if (totalPhotos > 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(totalPhotos, (index) {
                    final isActive = index == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isActive ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.primary : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),

            // 4. Footer Actions (if applicable)
            if (isMissing || widget.onEditPressed != null) ...[
              const Divider(height: 1, color: AppColors.divider),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: isMissing
                    ? Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.amber.shade800),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Reported missing. Mark as safe to edit.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                        ],
                      )
                    : SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Edit Pet Details'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            widget.onEditPressed!();
                          },
                        ),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPhotoState() {
    return Container(
      color: AppColors.surfaceMuted,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.pets, size: 48, color: AppColors.text3),
          SizedBox(height: 10),
          Text(
            'No photos available for this pet',
            style: TextStyle(color: AppColors.text3, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorPhotoState() {
    return Container(
      color: const Color(0xFF0F172A),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.broken_image_rounded, size: 42, color: Colors.white54),
          SizedBox(height: 8),
          Text(
            'Could not load photo',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
