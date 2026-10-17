import 'package:flutter/material.dart';
import 'package:paws_and_found/shared/molecules/feed_user_header.dart';
import 'package:paws_and_found/shared/molecules/feed_pet_info_card.dart';
import 'package:paws_and_found/shared/molecules/feed_card_footer.dart';

class ReportCardItem extends StatelessWidget {
  const ReportCardItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        FeedUserHeader(), 
        Padding(
          padding: EdgeInsets.all(10.0),
          child: FeedPetInfoCard(),
        ),
      // FeedCardFooter(),
      ],
      )
    );
  }
}
