import 'package:flutter/material.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';

void showVerificationDocsDialog(
  BuildContext context, {
  required String claimerName,
  required List<String> photoLabels,
  required List<String> docLabels,
}) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        '$claimerName\'s Proofs',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Photos Together with Pet:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
            const SizedBox(height: 6),
            if (photoLabels.isEmpty)
              const Text('None attached', style: TextStyle(fontSize: 12, color: AppColors.text3))
            else
              ...photoLabels.map(
                (p) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.image_outlined, color: AppColors.primary),
                  title: Text(p, style: const TextStyle(fontSize: 12.5)),
                ),
              ),
            const Divider(height: 20),
            const Text('Supporting Records (Audit Trail):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
            const SizedBox(height: 6),
            if (docLabels.isEmpty)
              const Text('None attached', style: TextStyle(fontSize: 12, color: AppColors.text3))
            else
              ...docLabels.map(
                (d) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.description_outlined, color: AppColors.accentOrange),
                  title: Text(d, style: const TextStyle(fontSize: 12.5)),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Done'),
        ),
      ],
    ),
  );
}