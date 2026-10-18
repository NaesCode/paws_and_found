import 'package:flutter/material.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';

class FeedActionBtns extends StatelessWidget {

  final String text;
  final Color backgroundColor;
  final VoidCallback onPressed;

  const FeedActionBtns({
    super.key, 
    required this.text, 
    required this.backgroundColor, 
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: 38,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: AppColors.background,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          onPressed: onPressed, 
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}
