import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paws_and_found/core/constants/app_assets.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';
import 'package:paws_and_found/features/feed/data/models/feed_post_model.dart';
import 'package:paws_and_found/features/feed/data/repositories/feed_repository_impl.dart';

/// An interactive embedded card representing a linked sighting report within a discussion thread.
///
/// Adheres to Atomic Design: Organism/Molecule displaying rich report metadata with a one-tap
/// deep link leading directly to the sighting post or community map.
class EmbeddedSightingCard extends StatefulWidget {
  final String reportId;

  const EmbeddedSightingCard({
    super.key,
    required this.reportId,
  });

  @override
  State<EmbeddedSightingCard> createState() => _EmbeddedSightingCardState();
}

class _EmbeddedSightingCardState extends State<EmbeddedSightingCard> {
  late Future<FeedPost?> _reportFuture;

  @override
  void initState() {
    super.initState();
    _reportFuture = FeedRepositoryImpl().getReportById(widget.reportId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FeedPost?>(
      future: _reportFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 70,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: AppColors.background2,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.text3.withValues(alpha: 0.2)),
            ),
            alignment: Alignment.center,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
                SizedBox(width: 8),
                Text(
                  'Loading linked sighting...',
                  style: TextStyle(fontSize: 12, color: AppColors.text3),
                ),
              ],
            ),
          );
        }

        final post = snapshot.data;
        if (post == null) {
          return const SizedBox.shrink(); // Gracefully omit if deleted or not found
        }

        final hasImage = post.imageUrl.isNotEmpty &&
            (post.imageUrl.startsWith('http://') || post.imageUrl.startsWith('https://'));

        return Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.contrast1, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header tag
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: AppColors.contrast1,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.remove_red_eye_rounded, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          'SIGHTING • ${post.status.toUpperCase()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    post.formattedTime,
                    style: const TextStyle(fontSize: 11, color: AppColors.text3),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Content row
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      width: 52,
                      height: 52,
                      child: hasImage
                          ? Image.network(
                              post.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Image.asset(
                                AppAssets.petPlaceholder,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Image.asset(
                              AppAssets.petPlaceholder,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${post.species} (${post.petName})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.darkCharcoal,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 13,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                post.location.isNotEmpty ? post.location : 'Pinned Area',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11.5, color: AppColors.text2),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Action button to view details
              InkWell(
                onTap: () {
                  // Direct navigation to map view centered on this sighting
                  context.go('/map?reportId=${post.id}');
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppColors.contrast1.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'View Sighting on Map',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.contrast1,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.contrast1),
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
}
