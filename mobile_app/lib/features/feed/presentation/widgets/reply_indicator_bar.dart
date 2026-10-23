import 'package:flutter/material.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';

class ReplyIndicatorBar extends StatelessWidget {
  final String username;
  final VoidCallback onClose;

  const ReplyIndicatorBar({
    super.key,
    required this.username,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0, right: 4.0),
      child: Row(
        children: [
          const Icon(Icons.reply_rounded, size: 16, color: AppColors.primary),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'Replying to @$username',
              style: const TextStyle(
                color: AppColors.text3,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: const Icon(Icons.close_rounded, size: 18, color: AppColors.text3),
          ),
        ],
      ),
    );
  }
}
