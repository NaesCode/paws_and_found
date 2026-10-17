import 'package:flutter/material.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';
import 'package:paws_and_found/shared/atoms/status_banner.dart';

//mao ni card for the name and the "missing" headline

class FeedUserHeader extends StatelessWidget {
  const FeedUserHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          dense: true,
          horizontalTitleGap: 8.0,
          minVerticalPadding: 5.0,
          leading: const CircleAvatar(
            backgroundColor: AppColors.contrast1,
            child: Icon(
              Icons.pets, 
              color: AppColors.background,
            ),
          ),
          // TODO: Need to fetch the name, profile, and time from the db
          title: const Text(
            'Princess Banana', 
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14.0,
              // fontFamily: 'MaterialFont',
            ),
          ),
          subtitle: const Text(
            '1 hour ago', 
            style: TextStyle(
              fontSize: 12.0,
              // fontFamily: 'MaterialFont'
            )
          ),
        ),
        // const SizedBox(height: 2),
        // should be dynamic based on what the type is according to the posts
        const StatusBanner(type: BannerType.missing),
          ],
      );
  }
}