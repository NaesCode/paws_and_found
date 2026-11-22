import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';
import 'package:paws_and_found/features/feed/data/models/feed_post_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> showConfirmMyPetDialog(
  BuildContext context,
  FeedPost report,
) async {
  final claimerId = Supabase.instance.client.auth.currentUser?.id;

  if (claimerId == null || claimerId.isEmpty){
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You must be logged in to claim a pet.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  if (claimerId == report.reporterId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You cannot claim your own report.')),
    );
    return;
  }

  final rawName = report.petName.trim();
  final isUnknown = rawName.isEmpty || rawName.toLowerCase() == 'unknown pet';
  final petLabel = isUnknown ? 'this unknown pet' : rawName;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        title: const Text(
          'Claim This Pet?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure $petLabel is yours? You will be redirected to verify ownership.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Yes, My Pet'),
          ),
        ],
      );
    },
  );

  if (confirmed == true && context.mounted) {
      context.push(
      '/claim?reportId=${report.id}',
      extra: report,
    );
  }
}