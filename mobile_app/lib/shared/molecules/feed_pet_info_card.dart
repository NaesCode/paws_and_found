import 'package:flutter/material.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';
import 'package:paws_and_found/shared/atoms/feed_action_btns.dart';
import 'package:paws_and_found/shared/molecules/feed_post_details.dart';

class FeedPetInfoCard extends StatelessWidget {
  const FeedPetInfoCard({super.key});

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
                // The Transparent pet Image overlay from db
                Positioned.fill(
                  child: Image.asset(
                    // TODO: Need to fetch data from the uploaded image from the backend instead of using a static placeholder
                    'assets/images/images.jpg',
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background, 
                  // border: Border.all(
                  //   color: AppColors.accentOrange, 
                  //   width: 1),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FeedPostDetails(),
              ),
              const SizedBox(height: 10),
              // TODO: need to like have a condition to change the button names, so that it will be usable inboth general and personal reports page
              Row(
                children: [
                  FeedActionBtns(
                    text: "Spotted", 
                    backgroundColor: AppColors.darkCharcoal, 
                    onPressed: (){
                      // TODO:function here
                    }
                  ),
                  const SizedBox(width: 8),
                  FeedActionBtns(
                    text: "Adopt", 
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
