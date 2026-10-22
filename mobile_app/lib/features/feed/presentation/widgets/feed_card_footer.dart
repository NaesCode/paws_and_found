import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';


class FeedCardFooter extends StatelessWidget {
  const FeedCardFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Container(
            clipBehavior: Clip.antiAlias,
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.darkCharcoal,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            // TODO: ibalhin sa lahi nga file like in atoms or such
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: RichText(
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis,
                    text: const TextSpan(
                      style: TextStyle(color: AppColors.darkCharcoal, fontSize: 14.0), 
                      children: [
                        TextSpan(
                          text: '@citrue: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: 'text sa tawo dayun if taas kay ellipses',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                GestureDetector(
                  onTap: () {
                    // TODO: function to do if ma click
                  },
                  child: const Text(
                    'See More',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentOrange,
                      fontSize: 14.0,
                    )
                  )
                )
              ],
            )
          ),
        ),
      ],
    );
  }
}