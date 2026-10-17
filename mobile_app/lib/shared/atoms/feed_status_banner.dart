import 'package:paws_and_found/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

enum BannerType{
  missing,
  spotted
}

class FeedStatusBanner extends StatelessWidget {

  final BannerType type;

  const FeedStatusBanner({
    super.key, 
    required this.type
  });

  @override
  Widget build(BuildContext context) {
    String statusText;
    Color bgColor;
    
    switch(type){
      case BannerType.missing:
        statusText = "MISSING";
        bgColor = AppColors.accentMaroon;
        break;
      case BannerType.spotted:
        statusText = "SPOTTED";
        bgColor = AppColors.accentOrange;
    }
    return Container(
      color: bgColor, 
      padding: const EdgeInsets.symmetric(vertical: 9.0),
      alignment: Alignment.center,
      child: Text(
        statusText,
        style: TextStyle(color: Colors.white,
        fontSize: 30,
        fontWeight: FontWeight.bold,
        letterSpacing: 6,
        ),
      ),
    );
  }
}