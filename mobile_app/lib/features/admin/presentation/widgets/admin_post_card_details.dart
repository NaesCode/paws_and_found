import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/admin_post_item.dart';
import 'admin_moderation_pill.dart';
import 'admin_post_status_pill.dart';

class AdminPostCard extends StatelessWidget {
  final AdminPostItem post;
  final VoidCallback onTap;
  final VoidCallback onActionTap;

  const AdminPostCard({
    super.key,
    required this.post,
    required this.onTap,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final isFlaggedItem = post.isFlagged || post.isModerationFlagged;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.0),
        child: Container(
          padding: const EdgeInsets.all(14.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.0),
            border: Border.all(
              color: isFlaggedItem
                  ? const Color(0xFFF59E0B)
                  : AppColors.border,
              width: isFlaggedItem ? 1.4 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ID & ACT.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildFieldLabel('ID'),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: Text(
                          post.id,
                          style: const TextStyle(
                            fontSize: 12.0,
                            color: AppColors.darkCharcoal,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const SizedBox(width: 8),
                      if (post.isFlagged)
                        Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              '!',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 12.0,
                              ),
                            ),
                          ),
                        ),
                      InkWell(
                        onTap: onActionTap,
                        borderRadius: BorderRadius.circular(6.0),
                        child: Container(
                          width: 30,
                          height: 26,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(6.0),
                            border: Border.all(
                              color: AppColors.border,
                              width: 1.0,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            '···',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 14.0,
                              fontWeight: FontWeight.w900,
                              height: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10.0),
                child: Divider(height: 1, thickness: 1, color: AppColors.divider),
              ),

              // Animal Info (Left) & ANIMAL STATUS + Status Pill (Right)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.title,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkCharcoal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (post.subtitle != null &&
                            post.subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            post.subtitle!,
                            style: const TextStyle(
                              fontSize: 12.0,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildFieldLabel('ANIMAL STATUS'),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AdminPostStatusPill(status: post.status),
                          if (isFlaggedItem) ...[
                            const SizedBox(width: 6),
                            AdminModerationPill(status: post.moderationStatus),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),

              //USER & Date
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 7.0,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  children: [
                    _buildFieldLabel('USER'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        post.username,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.darkCharcoal,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      post.dateFormatted,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
        letterSpacing: 0.5,
      ),
    );
  }
}