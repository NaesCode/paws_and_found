import 'package:flutter/material.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';
import './feed_status_banner.dart';

class FeedUserHeader extends StatelessWidget {

  final BannerType bannerType;
  final String userName;
  final String timeAgo;
  final String location;

  const FeedUserHeader({
    super.key,
    required this.bannerType,
    required this.userName,
    required this.timeAgo,
    required this.location,
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
              const CircleAvatar(
                backgroundColor: AppColors.contrast1,
                child: Icon(
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
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.0,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Transform.translate(
                          offset: const Offset(-2.5, 0), //aron ma align sa left
                          child: Icon(
                            Icons.location_on_rounded, 
                            size: 13, 
                            color: AppColors.text3,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '$location  •  $timeAgo',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.0, 
                              color: Colors.grey,
                            ),
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
