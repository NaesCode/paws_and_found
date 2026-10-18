import 'package:flutter/material.dart';
import './feed_user_header.dart';
import './feed_pet_info_card.dart';
import './feed_card_footer.dart';
import './feed_status_banner.dart';

class ReportCardItem extends StatelessWidget {
  final String button1Text;
  final String button2Text;
  final VoidCallback onButton1Pressed;
  final VoidCallback onButton2Pressed;

  //data
  final String petName;
  final String postedBy;
  final String species;
  final String location;
  final String description;
  final String formattedTime;
  final String imageURL;
  final BannerType bannerType;

  const ReportCardItem({
    super.key,
    required this.button1Text,
    required this.button2Text,
    required this.onButton1Pressed,
    required this.onButton2Pressed,
    required this.bannerType,
    this.imageURL = 'assets/images/images.jpg', //default TODO: change to decent picture
    required this.petName,
    required this.postedBy,
    required this.species,
    required this.location,
    required this.description,
    required this.formattedTime,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FeedUserHeader(
          bannerType: bannerType,
          userName: postedBy,
          timeAgo: formattedTime,
          location: location,
        ), 
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 10.0, 
            vertical: 8.0),
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
        Padding(padding: EdgeInsets.symmetric(
          horizontal: 12.0, 
          vertical: 10.0),
        child:  FeedCardFooter(),
        )
      ],
      )
    );
  }
}
