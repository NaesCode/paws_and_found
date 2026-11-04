import 'package:flutter/material.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/wireframe_colors.dart';
import '../../data/models/ai_match_candidate.dart';

/// Presentation widget displaying real-time AI match suggestions on the Camera screen.
///
/// Features:
/// - Shimmer / pulse scanning state while AI analyzes in-memory photo bytes
/// - Visual match cards displaying pet photo, name, visual similarity badge, and distance
/// - One-tap linking action to attach sighting to the missing pet report
class AiMatchScannerCard extends StatelessWidget {
  final bool isScanning;
  final List<AiMatchCandidate> candidates;
  final AiMatchCandidate? selectedCandidate;
  final ValueChanged<AiMatchCandidate> onSelectCandidate;
  final VoidCallback onClearSelection;
  final VoidCallback? onViewAllCandidates;
  final VoidCallback? onManualSearch;

  const AiMatchScannerCard({
    super.key,
    required this.isScanning,
    required this.candidates,
    this.selectedCandidate,
    required this.onSelectCandidate,
    required this.onClearSelection,
    this.onViewAllCandidates,
    this.onManualSearch,
  });

  @override
  Widget build(BuildContext context) {
    if (isScanning) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: WireframeColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: WireframeColors.primaryDark.withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: WireframeColors.primaryDark,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Visual Scanner Active',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: WireframeColors.primaryDark,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Scanning active missing pet reports nearby for visual matches...',
                    style: TextStyle(
                      fontSize: 11,
                      color: WireframeColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 1. A candidate is currently selected/linked
    if (selectedCandidate != null) {
      final pet = selectedCandidate!;
      final hasPic = pet.photoUrl.isNotEmpty &&
          (pet.photoUrl.startsWith('http://') || pet.photoUrl.startsWith('https://'));

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F8E9), // Light green tint for confirmation
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF558B2F), width: 1.2),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 48,
                height: 48,
                child: hasPic
                    ? Image.network(
                        pet.photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Image.asset(
                          AppAssets.petPlaceholder,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(AppAssets.petPlaceholder, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF33691E),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${pet.similarityPercent}% MATCH',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'LINKED TO ${pet.petName.toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${pet.species} • ${pet.lastSeenLocation ?? "Cebu Area"}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: WireframeColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20, color: WireframeColors.textSecondary),
              tooltip: 'Unlink from this pet',
              onPressed: onClearSelection,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      );
    }

    // 2. No candidate selected yet, but candidates were found!
    if (candidates.isNotEmpty) {
      final topMatch = candidates.first;
      final otherCount = candidates.length - 1;
      final hasPic = topMatch.photoUrl.isNotEmpty &&
          (topMatch.photoUrl.startsWith('http://') || topMatch.photoUrl.startsWith('https://'));

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: WireframeColors.primaryDark, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, size: 16, color: WireframeColors.primaryDark),
                const SizedBox(width: 6),
                const Text(
                  'AI Match Suggestion',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: WireframeColors.primaryDark,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: topMatch.isHighConfidence ? Colors.green.shade700 : Colors.orange.shade800,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${topMatch.similarityPercent}% Visual Match',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: hasPic
                        ? Image.network(
                            topMatch.photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Image.asset(
                              AppAssets.petPlaceholder,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Image.asset(AppAssets.petPlaceholder, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topMatch.petName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: WireframeColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${topMatch.species} • Missing in ${topMatch.lastSeenLocation ?? "Cebu"}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: WireframeColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (topMatch.distanceKm != null)
                        Text(
                          '${topMatch.distanceKm} km from your pin',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WireframeColors.primaryDark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.link_rounded, size: 16),
                    label: Text(
                      'Link to ${topMatch.petName}',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => onSelectCandidate(topMatch),
                  ),
                ),
                if (otherCount > 0 && onViewAllCandidates != null) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: WireframeColors.textPrimary,
                      side: const BorderSide(color: WireframeColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    onPressed: onViewAllCandidates,
                    child: Text(
                      '+$otherCount others',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    }

    // 3. Fallback: No candidate scan done or scan found nothing
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: WireframeColors.primaryDark,
          side: const BorderSide(color: WireframeColors.border, width: 1.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        icon: const Icon(Icons.search_rounded, size: 18),
        label: const Text(
          'Search & link to a Missing Pet report (Optional)',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        onPressed: onManualSearch,
      ),
    );
  }
}

