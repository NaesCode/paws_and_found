import 'package:flutter/material.dart';
import 'package:paws_and_found/core/constants/app_assets.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';
import 'package:paws_and_found/features/feed/presentation/widgets/feed_action_btns.dart';
import 'package:paws_and_found/features/feed/presentation/widgets/feed_post_details.dart';

class FeedPetInfoCard extends StatelessWidget {

  final String button1Text;
  final String button2Text;
  final VoidCallback onButton1Pressed;
  final VoidCallback onButton2Pressed;
  final String imageUrl;
  final String name;
  final String specie;
  final String description;

  const FeedPetInfoCard({
    super.key,
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Side
        Expanded(
          flex: 4,
          child: Container(
            height: 195, 
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
                child: (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'))
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.fill,
                        errorBuilder: (_, _, _) => Image.asset(
                          AppAssets.petPlaceholder,
                          fit: BoxFit.fill,
                        ),
                      )
                    : Image.asset(
                        // Only attempt to load if it looks like a valid asset path (e.g., contains 'assets/')
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
                height: 140, // aron constant lang
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background, 
                  // border: Border.all(
                  //   color: AppColors.accentOrange, 
                  //   width: 1),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FeedPostDetails(
                  // TODO: need to change data from db
                  name: name,
                  specie: specie,
                  description: description,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  FeedActionBtns(
                    text: button1Text, 
                    backgroundColor: AppColors.darkCharcoal, 
                    onPressed: (){
                      // TODO:function here
                    }
                  ),
                  const SizedBox(width: 8),
                  FeedActionBtns(
                    text: button2Text, 
                    backgroundColor: AppColors.primary, 
                    onPressed: (){
                      // TODO:function here
                    }
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
