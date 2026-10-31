import 'package:flutter/material.dart';
import 'package:paws_and_found/core/constants/app_assets.dart';
import './feed_user_header.dart';
import './feed_pet_info_card.dart';
import './feed_card_footer.dart';
import './feed_status_banner.dart';

class ReportCardItem extends StatelessWidget {
  final String button1Text;
  final String button2Text;
  final VoidCallback onButton1Pressed;
  final VoidCallback onButton2Pressed;

  final String petName;
  final String postedBy;
  final String species;
  final String location; 
  final String description;
  final String formattedTime;
  final String imageURL; 
  final String userImageUrl;
  final BannerType bannerType;
  final VoidCallback? onUndoPressed;
  final bool isFlagged;

  const ReportCardItem({
    super.key,
    required this.button1Text,
    required this.button2Text,
    required this.onButton1Pressed,
    required this.onButton2Pressed,
    required this.bannerType,
    this.imageURL = AppAssets.petPlaceholder,
    required this.petName,
    required this.postedBy,
    required this.species,
    required this.location,
    required this.description,
    required this.formattedTime,
    required this.userImageUrl,
    this.onUndoPressed,
    this.isFlagged = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FeedUserHeader(
            bannerType: bannerType,
            userImageUrl: userImageUrl,
            userName: postedBy,
            timeAgo: formattedTime,
            location: location.isNotEmpty ? location : "No location pinned",
            onUndoPressed: onUndoPressed,
          ),
          if (isFlagged)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFB74D), width: 1),
              ),
              child: const Row(
                children: [
                  Icon(Icons.flag_rounded, size: 16, color: Color(0xFFE65100)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Flagged: Under review by content moderation',
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFB71C1C),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
            child: FeedPetInfoCard(
              button1Text: button1Text,
              button2Text: button2Text,
              onButton1Pressed: onButton1Pressed,
              onButton2Pressed: onButton2Pressed,
              imageUrl: imageURL,
              name: petName,
              specie: species,
              description: description,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
            child: FeedCardFooter(),
          )
        ],
      ),
    );
  }
}
