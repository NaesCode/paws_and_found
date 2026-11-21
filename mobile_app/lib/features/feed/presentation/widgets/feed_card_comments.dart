import 'package:flutter/material.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';

class FeedCardComments extends StatelessWidget {
  final VoidCallback? onReplyTap;
  final VoidCallback? onEditTap;
  final VoidCallback? onDeleteTap;
  final String username;
  final String timeAgo;
  final String commentText;
  final String? userPhotoUrl;
  final String? linkedReportId;
  final bool isReply;
  final bool isCurrentUser;

  const FeedCardComments({
    super.key,
    this.onReplyTap,
    this.onEditTap,
    this.onDeleteTap,
    required this.commentText,
    required this.timeAgo,
    required this.username,
    this.userPhotoUrl,
    this.linkedReportId,
    this.isReply = false,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = userPhotoUrl != null &&
        (userPhotoUrl!.startsWith('http://') || userPhotoUrl!.startsWith('https://'));

    final double avatarRadius = isReply ? 14.0 : 16.0;
    const double avatarGap = 10.0;
    final double bodyIndent = (avatarRadius * 2) + avatarGap;

    return Padding(
      padding: EdgeInsets.only(
        top: isReply ? 4.0 : 8.0,
        bottom: 8.0,
        left: isReply ? 48.0 : 16.0,
        right: 16.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: avatarRadius,
                backgroundColor: AppColors.contrast1.withValues(alpha: 0.2),
                backgroundImage: hasPhoto ? NetworkImage(userPhotoUrl!) : null,
                child: hasPhoto
                    ? null
                    : Icon(
                        Icons.person,
                        size: isReply ? 16 : 18,
                        color: AppColors.contrast1,
                      ),
              ),
              const SizedBox(width: avatarGap),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.text2,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.0,
                        ),
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
              ),
              if (isCurrentUser) ...[
                const SizedBox(width: 8.0),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.more_horiz, size: 18, color: AppColors.text3),
                  onSelected: (value) {
                    if (value == 'edit') onEditTap?.call();
                    if (value == 'delete') onDeleteTap?.call();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 16),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 4.0),
          Padding(
            padding: EdgeInsets.only(left: bodyIndent),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  commentText,
                  style: const TextStyle(
                    color: AppColors.text2,
                    fontSize: 14.0,
                    height: 1.3,
                  ),
                ),
                // if (linkedReportId != null && linkedReportId!.isNotEmpty) ...[
                //   EmbeddedSightingCard(reportId: linkedReportId!),
                //   const SizedBox(height: 4.0),
                // ],
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