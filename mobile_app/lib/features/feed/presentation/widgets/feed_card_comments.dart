import 'package:flutter/material.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';
import 'package:paws_and_found/features/feed/presentation/widgets/embedded_sighting_card.dart';

class FeedCardComments extends StatelessWidget {
  final VoidCallback? onReplyTap;
  final String username;
  final String timeAgo;
  final String commentText;
  final String? userPhotoUrl;
  final String? linkedReportId;

  const FeedCardComments({
    super.key,
    this.onReplyTap,
    required this.commentText,
    required this.timeAgo,
    required this.username,
    this.userPhotoUrl,
    this.linkedReportId,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = userPhotoUrl != null &&
        (userPhotoUrl!.startsWith('http://') || userPhotoUrl!.startsWith('https://'));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.contrast1.withValues(alpha: 0.2),
            backgroundImage: hasPhoto ? NetworkImage(userPhotoUrl!) : null,
            child: hasPhoto
                ? null
                : const Icon(Icons.person, size: 20, color: AppColors.contrast1),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        color: AppColors.text2,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.0,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      timeAgo,
                      style: const TextStyle(
                        color: AppColors.text3,
                        fontSize: 12.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4.0),
                Text(
                  commentText,
                  style: const TextStyle(
                    color: AppColors.text2,
                    fontSize: 14.0,
                    height: 1.3,
                  ),
                ),
                if (linkedReportId != null && linkedReportId!.isNotEmpty) ...[
                  EmbeddedSightingCard(reportId: linkedReportId!),
                  const SizedBox(height: 4.0),
                ],
                const SizedBox(height: 6.0),
                GestureDetector(
                  onTap: onReplyTap,
                  child: const Text(
                    'Reply',
                    style: TextStyle(
                      color: AppColors.text3,
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
