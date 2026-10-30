import 'package:flutter/material.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';
import 'package:paws_and_found/features/feed/presentation/widgets/feed_comments_modal.dart';

void showFeedCommentsModal(BuildContext context, {String? reportId, String? petName}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (modalContext) {
      return FeedCommentsModal(
        reportId: reportId,
        petName: petName,
      );
    },
  );
}

class FeedCardFooter extends StatelessWidget {
  final String? reportId;
  final String? petName;

  const FeedCardFooter({
    super.key,
    this.reportId,
    this.petName,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => showFeedCommentsModal(context, reportId: reportId, petName: petName),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.forum_outlined, size: 14, color: AppColors.darkCharcoal),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'View community discussion & sightings',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.darkCharcoal,
                              fontSize: 13.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    'Thread →',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentOrange,
                      fontSize: 13.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
