import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';
import 'package:paws_and_found/features/feed/data/models/feed_post_model.dart';
import 'package:paws_and_found/features/feed/data/repositories/feed_repository_impl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> showConfirmMyPetDialog(
  BuildContext context,
  FeedPost report,
) async {
  final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
  final isBlocked = await FeedRepositoryImpl().hasActiveClaimByOther(
    report.id,
    currentUserId,
  );

  if (!context.mounted) return;

  final String petDisplayName =
      report.petName.isNotEmpty && report.petName.toLowerCase() != 'unknown'
          ? report.petName
          : 'this ${report.species.isNotEmpty ? report.species.toLowerCase() : 'pet'}';

  if (isBlocked) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        title: const Row(
          children: [
            Icon(Icons.hourglass_top_rounded, color: AppColors.accentOrange),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Claim Currently in Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'You cannot claim $petDisplayName right now because another claimant submitted a request before you and is currently undergoing verification. Please check back later if that claim is not completed.',
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Got it',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    return;
  }

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      title: Text(
        'Claim $petDisplayName?',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        'Are you sure $petDisplayName is your pet? Proceeding will start the ownership verification and recovery process with the finder.',
        style: const TextStyle(height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentOrange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () {
            Navigator.of(ctx).pop();
            context.push('/claim?reportId=${report.id}', extra: report);
          },
          child: const Text(
            'Yes, Claim Pet',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}