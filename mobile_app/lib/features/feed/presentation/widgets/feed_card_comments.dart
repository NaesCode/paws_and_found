import 'package:flutter/material.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';
// import 'package:paws_and_found/features/feed/presentation/widgets/feed_comments_modal.dart';


class FeedCardComments extends StatelessWidget {

  final VoidCallback? onReplyTap;
  final String username;
  final String timeAgo;
  final String commentText;

  const FeedCardComments({
    super.key,
    this.onReplyTap,
    required this.commentText,
    required this.timeAgo,
    required this.username,
    });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TODO: change to receive pfp
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.text3,
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
                      style: TextStyle(
                        color: AppColors.text3,
                        fontSize: 12.0,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 4.0),
                Text(
                  commentText,
                  style: TextStyle(
                    color: AppColors.text2,
                    fontSize: 14.0,
                    height: 1.3
                  ),
                ),
                const SizedBox(height: 6.0),
                GestureDetector(
                  onTap: onReplyTap,
                  child: const Text(
                    'Reply',
                    style: TextStyle(
                      color: AppColors.text3,
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                    )
                  )
                )
              ],
            )
          ) 
        ],
      )
    );
  }
}