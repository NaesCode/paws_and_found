import 'package:flutter/material.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';

void showUserProfilePreviewDialog(
  BuildContext context, {
  required String name,
  required String roleLabel,
  required String joinedText,
  required int totalReports,
  required int verifiedReunions,
  String avatarUrl = '',
  String email = '',
  String phone = '',
}) {
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.primary.withValues(alpha: 0.14),
              backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
              child: avatarUrl.isEmpty
                  ? const Icon(Icons.person_rounded, size: 34, color: AppColors.primary)
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.darkCharcoal),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                roleLabel,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 6),
            Text(joinedText, style: const TextStyle(fontSize: 12, color: AppColors.text3)),
            const SizedBox(height: 14),

            // Contact Details Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _contactRow(
                    Icons.email_outlined,
                    email.isNotEmpty ? email : 'No email provided',
                  ),
                  const SizedBox(height: 8),
                  _contactRow(
                    Icons.phone_outlined,
                    phone.isNotEmpty ? phone : 'No phone number provided',
                  ),
                ],
              ),
            ),

            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statItem('$totalReports', 'Reports'),
                _statItem('$verifiedReunions', 'Reunions'),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _contactRow(IconData icon, String value) {
  return Row(
    children: [
      Icon(icon, size: 16, color: AppColors.primary),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(fontSize: 12.5, color: AppColors.darkCharcoal),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

Widget _statItem(String count, String label) {
  return Column(
    children: [
      Text(count, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkCharcoal)),
      Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.text3)),
    ],
  );
}