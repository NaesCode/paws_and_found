import 'package:flutter/material.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';

Future<bool?> showHandoverConfirmDialog(
  BuildContext context, {
  required String petName,
  required bool isFinder,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Confirm Safe Handover?',
        style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
      ),
      content: Text(
        isFinder
            ? 'Confirm that you have safely handed over $petName to the verified owner. Once both sides confirm, this report will be marked as FOUND.'
            : 'Confirm that you have safely received $petName. Once both sides confirm, this recovery case will be closed.',
        style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.text2),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Not Yet'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Yes, Handover Complete', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}