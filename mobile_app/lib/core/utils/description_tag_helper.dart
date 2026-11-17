import 'package:flutter/material.dart';

/// Helper to parse and format embedded metadata tags inside report descriptions,
/// specifically `[Mobility: <type>]` and `[AI Match: <percent>%]`.
class DescriptionTagHelper {
  static final RegExp _mobilityRegex =
      RegExp(r'\[Mobility:\s*([^\]]+)\]', caseSensitive: false);
  static final RegExp _matchRegex =
      RegExp(r'\[AI Match:\s*(\d+)%?\]', caseSensitive: false);

  /// Extracts the raw mobility string (e.g. 'standard', 'flighted', 'roaming', 'distant')
  static String? extractMobility(String? description) {
    if (description == null || description.isEmpty) return null;
    final match = _mobilityRegex.firstMatch(description);
    return match?.group(1)?.trim();
  }

  /// Extracts the AI match confidence integer string (e.g. '94')
  static String? extractMatchConfidence(String? description) {
    if (description == null || description.isEmpty) return null;
    final match = _matchRegex.firstMatch(description);
    return match?.group(1)?.trim();
  }

  /// Returns the description with all internal metadata tags stripped cleanly.
  static String cleanDescription(String? description) {
    if (description == null || description.isEmpty) return '';
    return description
        .replaceAll(_mobilityRegex, '')
        .replaceAll(_matchRegex, '')
        .trim();
  }

  /// Human-readable label for a mobility assumption type
  static String mobilityLabel(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'flighted':
        return 'Avian / Flighted (≤ 60 km)';
      case 'roaming':
        return 'Active Roamer (≤ 30 km)';
      case 'distant':
        return 'Suspected Transport (≤ 150 km)';
      case 'standard':
      default:
        return 'Limited Roam (≤ 10 km)';
    }
  }

  /// Contextual icon for a mobility assumption type
  static IconData mobilityIcon(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'flighted':
        return Icons.flutter_dash_rounded;
      case 'roaming':
        return Icons.directions_run_rounded;
      case 'distant':
        return Icons.directions_car_rounded;
      case 'standard':
      default:
        return Icons.pets_rounded;
    }
  }

  /// Builds a prominent, styled mobility badge card with clear visual separation
  static Widget buildMobilityCard(String mobility, {bool compact = false}) {
    final label = mobilityLabel(mobility);
    final icon = mobilityIcon(mobility);

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFBFDBFE), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: const Color(0xFF1D4ED8)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D4ED8),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1.0),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF1D4ED8)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Mobility Assumption',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E40AF),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds an AI match confidence card
  static Widget buildAiMatchCard(String percentStr, {bool compact = false}) {
    final score = int.tryParse(percentStr) ?? 0;
    final isHigh = score >= 85;

    final bg = isHigh ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB);
    final border = isHigh ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A);
    final fg = isHigh ? const Color(0xFF15803D) : const Color(0xFFB45309);

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: border, width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 11, color: fg),
            const SizedBox(width: 4),
            Text(
              '$percentStr% AI Match',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: fg,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 16, color: fg),
          const SizedBox(width: 8),
          Text(
            'AI Visual Match: $percentStr% Confidence',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
