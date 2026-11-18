import 'package:flutter/material.dart';
import 'package:paws_and_found/core/constants/app_assets.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';
import 'package:paws_and_found/features/feed/presentation/widgets/feed_action_btns.dart';
import 'package:paws_and_found/features/feed/presentation/widgets/feed_post_details.dart';
import 'package:paws_and_found/features/feed/presentation/widgets/feed_claim_btn.dart';
import 'package:paws_and_found/features/feed/presentation/widgets/post_image_popup.dart';

class FeedPetInfoCard extends StatelessWidget {
  final String button1Text;
  final String button2Text;
  final VoidCallback onButton1Pressed;
  final VoidCallback onButton2Pressed;
  final String imageUrl;
  final String name;
  final String specie;
  final String description;
  final String petButtonText;         
  final VoidCallback onPetButtonPressed; 

  const FeedPetInfoCard({
    super.key,
    required this.petButtonText,
    required this.onPetButtonPressed,
    required this.button1Text,
    required this.button2Text,
    required this.onButton1Pressed,
    required this.onButton2Pressed,
    this.imageUrl = AppAssets.petPlaceholder,
    required this.name,
    required this.specie,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasNetworkImage =
        imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Side
        Expanded(
          flex: 4,
          child: GestureDetector(
            onTap: hasNetworkImage
                ? () => showImageZoomDialog(context, imageUrl: imageUrl)
                : null,
            child: Container(
              height: 240,
              color: Colors.white,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Positioned(
                    bottom: 0,
                    // sudlanan sa pic
                    child: Container(
                      width: 125,
                      height: 155,
                      decoration: const BoxDecoration(
                        color: AppColors.accentOrange, 
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(65),
                          topRight: Radius.circular(65),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: hasNetworkImage
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.fill,
                            errorBuilder: (_, __, ___) => Image.asset(
                              AppAssets.petPlaceholder,
                              fit: BoxFit.fill,
                            ),
                          )
                        : Image.asset(
                            (imageUrl.isNotEmpty && imageUrl.contains('/'))
                                ? imageUrl
                                : AppAssets.petPlaceholder,
                            fit: BoxFit.fill,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        
        // Right Side
        Expanded(
          flex: 5,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Content Box 
              Container(
                width: double.infinity,
                height: 146,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.background, 
                  borderRadius: BorderRadius.circular(4),
                  borderRadius: BorderRadius.circular(2),
                ),
                clipBehavior: Clip.antiAlias,
                child: FeedPostDetails(
                  name: name,
                  specie: specie,
                  description: description,
                ),
              ),
              const SizedBox(height: 10),

              FeedClaimBtn(
                text: petButtonText,
                onPressed: onPetButtonPressed,
              ),
              const SizedBox(height: 8),

              // Existing Action Buttons
              Row(
                children: [
                  FeedActionBtns(
                    text: button1Text, 
                    backgroundColor: AppColors.darkCharcoal, 
                    onPressed: onButton1Pressed,
                  ),
                  const SizedBox(width: 8),
                  FeedActionBtns(
                    text: button2Text, 
                    backgroundColor: AppColors.primary, 
                    onPressed: onButton2Pressed,
                  )
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}