import 'package:flutter/material.dart';

void showImageZoomDialog(BuildContext context, {required String imageUrl}) {
  if (imageUrl.isEmpty) return;
  
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.85),
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16.0),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Tapping outside the image closes the popup
            GestureDetector(
              onTap: () => Navigator.of(dialogContext).pop(),
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),

            // Pinch-to-zoom & pan container
            InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              clipBehavior: Clip.none,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Stack(
                  children: [
                    Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Padding(
                          padding: EdgeInsets.all(48.0),
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => const Padding(
                        padding: EdgeInsets.all(48.0),
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white70,
                          size: 48,
                        ),
                      ),
                    ),

                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => Navigator.of(dialogContext).pop(),
                          child: const Padding(
                            padding: EdgeInsets.all(6.0),
                            child: Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}