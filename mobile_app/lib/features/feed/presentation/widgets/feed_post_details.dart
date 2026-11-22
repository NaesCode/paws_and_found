import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final matchRegex = RegExp(r'\[AI Match:\s*(\d+)%?\]', caseSensitive: false);
    final match = matchRegex.firstMatch(description);
    final matchConfidence = match?.group(1);
    final cleanDescription = description.replaceAll(matchRegex, '').trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (matchConfidence != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color:
                  int.tryParse(matchConfidence) != null &&
                      int.parse(matchConfidence) >= 85
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color:
                    int.tryParse(matchConfidence) != null &&
                        int.parse(matchConfidence) >= 85
                    ? const Color(0xFF81C784)
                    : const Color(0xFFFFB74D),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 11,
                  color:
                      int.tryParse(matchConfidence) != null &&
                          int.parse(matchConfidence) >= 85
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFE65100),
                ),
                const SizedBox(width: 4),
                Text(
                  '$matchConfidence% AI Match',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color:
                        int.tryParse(matchConfidence) != null &&
                            int.parse(matchConfidence) >= 85
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFE65100),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
        Text(
          'Name: $name',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Specie: $specie',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Description:',
          style: TextStyle(fontSize: 11, color: Colors.black54),
        ),
        const SizedBox(height: 2),
        Text(
          cleanDescription.isNotEmpty
              ? cleanDescription
              : 'No description provided.',
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black87,
            height: 1.3,
          ),
          maxLines: matchConfidence != null ? 2 : 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
