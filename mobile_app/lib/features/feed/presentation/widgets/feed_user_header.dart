import 'package:flutter/material.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';
import './feed_status_banner.dart';

class FeedUserHeader extends StatelessWidget {
  final BannerType bannerType;
  final String userName;
  final String timeAgo;
  final String location;
  final String userImageUrl;

  const FeedUserHeader({
    super.key,
    required this.bannerType,
    required this.userName,
    required this.timeAgo,
    required this.location,
    required this.userImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.contrast1,
                backgroundImage: (userImageUrl.startsWith('http://') || userImageUrl.startsWith('https://'))
                    ? NetworkImage(userImageUrl)
                    : null, 
                child: (userImageUrl.startsWith('http://') || userImageUrl.startsWith('https://'))
                    ? null
                    : const Icon(
                        Icons.pets, 
                        color: AppColors.background,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName, 
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.0,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Transform.translate(
                          offset: const Offset(-2.5, 0), // aligns cleanly to the left
                          child: const Icon(
                            Icons.location_on_rounded, 
                            size: 13, 
                            color: AppColors.text3,
                          ),
                        ),
                        // Flexible lets the location shrink and truncate if it's too long
                        Flexible(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.0, 
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        // The timestamp is kept outside the Flexible widget so it's guaranteed to be seen
                        Text(
                          '  •  $timeAgo',
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 12.0, 
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        FeedStatusBanner(type: bannerType),
      ],
    );
  }
}
