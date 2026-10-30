import 'package:flutter/material.dart';
import 'package:paws_and_found/core/constants/app_assets.dart';
import 'package:paws_and_found/core/utils/location_helper.dart';
import './feed_user_header.dart';
import './feed_pet_info_card.dart';
import './feed_card_footer.dart';
import './feed_status_banner.dart';

class ReportCardItem extends StatefulWidget {
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
  });

  @override
  State<ReportCardItem> createState() => _ReportCardItemState();
}

class _ReportCardItemState extends State<ReportCardItem> {
  late Future<String> _addressFuture;

  @override
  void initState() {
    super.initState();
    // Cache the execution of the lookup so scrolling won't force multi-network trips
    _addressFuture = const LocationService().getAddressFromHexEWKB(widget.location);
  }

  @override
  void didUpdateWidget(covariant ReportCardItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the location string alters dynamically, trigger a refreshed fetch execution
    if (oldWidget.location != widget.location) {
      _addressFuture = const LocationService().getAddressFromHexEWKB(widget.location);
    }
  }

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
          FutureBuilder<String>(
            future: _addressFuture,
            builder: (context, snapshot) {
              final addressLabel = snapshot.data ?? "Resolving address...";
              
              return FeedUserHeader(
                bannerType: widget.bannerType,
                userImageUrl: widget.userImageUrl,
                userName: widget.postedBy,
                timeAgo: widget.formattedTime,
                location: addressLabel, 
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
            child: FeedPetInfoCard(
              button1Text: widget.button1Text,
              button2Text: widget.button2Text,
              onButton1Pressed: widget.onButton1Pressed,
              onButton2Pressed: widget.onButton2Pressed,
              imageUrl: widget.imageURL,
              name: widget.petName,
              specie: widget.species,
              description: widget.description,
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
