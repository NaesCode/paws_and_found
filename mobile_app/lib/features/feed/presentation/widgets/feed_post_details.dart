import 'package:flutter/material.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';

class FeedPostDetails extends StatelessWidget {
  final String name;
  final String specie;
  final String description;

  const FeedPostDetails({
    super.key,
    required this.name,
    required this.specie,
    required this.description,
  });

  void _showFullDescriptionDialog(
    BuildContext context, {
    required String cleanDescription,
    String? matchConfidence,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        titlePadding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 16, 12),
        title: Row(
          children: [
            Expanded(
              child: Text(
                name.isNotEmpty ? name : 'Pet Details',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkCharcoal,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Specie: $specie',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text2,
                ),
              ),
              if (matchConfidence != null) ...[
                const SizedBox(height: 8),
                _buildMatchBadge(matchConfidence),
              ],
              const SizedBox(height: 12),
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                cleanDescription,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.darkCharcoal,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Close',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchBadge(String matchConfidence) {
    final isHighMatch =
        int.tryParse(matchConfidence) != null && int.parse(matchConfidence) >= 85;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isHighMatch ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isHighMatch ? const Color(0xFF81C784) : const Color(0xFFFFB74D),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 11,
            color: isHighMatch ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
          ),
          const SizedBox(width: 4),
          Text(
            '$matchConfidence% AI Match',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isHighMatch ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final matchRegex = RegExp(r'\[AI Match:\s*(\d+)%?\]', caseSensitive: false);
    final match = matchRegex.firstMatch(description);
    final matchConfidence = match?.group(1);
    final cleanDescription = description.replaceAll(matchRegex, '').trim();
    final hasDescription = cleanDescription.isNotEmpty;
    final maxDescLines = matchConfidence != null ? 1 : 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (matchConfidence != null) ...[
          _buildMatchBadge(matchConfidence),
          const SizedBox(height: 3),
        ],
        Text(
          'Name: $name',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13.5,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Specie: $specie',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13.5,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Description:',
          style: TextStyle(fontSize: 11, color: Colors.black54),
        ),
        const SizedBox(height: 1),
        LayoutBuilder(
          builder: (context, constraints) {
            final textStyle = const TextStyle(
              fontSize: 11,
              color: Colors.black87,
              height: 1.25,
            );
            final displayText =
                hasDescription ? cleanDescription : 'No description provided.';

            final span = TextSpan(text: displayText, style: textStyle);
            final tp = TextPainter(
              text: span,
              maxLines: maxDescLines,
              textDirection: Directionality.of(context),
            )..layout(maxWidth: constraints.maxWidth);

            final didOverflow = hasDescription && tp.didExceedMaxLines;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayText,
                  style: textStyle,
                  maxLines: maxDescLines,
                  overflow: TextOverflow.ellipsis,
                ),
                if (didOverflow) ...[
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: () => _showFullDescriptionDialog(
                      context,
                      cleanDescription: cleanDescription,
                      matchConfidence: matchConfidence,
                    ),
                    child: const Text(
                      'See more',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}
