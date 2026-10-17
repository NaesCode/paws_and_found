import 'package:flutter/material.dart';
import '../../core/theme/wireframe_colors.dart';
import '../atoms/wireframe_status_badge.dart';
import '../atoms/wireframe_tag.dart';

/// A floating report detail card organism shown at the bottom of the map view.
///
/// Displays:
/// - Animal photo placeholder frame
/// - Animal Name / Breed Title
/// - Status Badge ("MISSING", "STRAY", "FOUND")
/// - Location & Recency Subtitle ("Near Elm St · 2h ago")
/// - Attribute Tags (e.g., "Male", "Adult", "Golden")
///
/// Adheres to Atomic Design: dumb, stateless UI element relying purely on
/// passed properties and callbacks.
class MapReportCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final List<String> tags;
  final String? photoUrl;
  final VoidCallback? onTap;
  final VoidCallback? onClose;

  const MapReportCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.tags,
    this.photoUrl,
    this.onTap,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: WireframeColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: WireframeColors.borderLight, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Image / Photo Placeholder
            _buildPhotoPlaceholder(),
            const SizedBox(width: 14),

            // Right: Content Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title + Status Badge Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: WireframeColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      WireframeStatusBadge(status: status),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Subtitle (Location & Time Ago)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: WireframeColors.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Tags Row
                  if (tags.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: tags.map((t) => WireframeTag(label: t)).toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPlaceholder() {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: WireframeColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WireframeColors.border, width: 1.0),
      ),
      child: photoUrl != null && photoUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.network(
                photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _placeholderIcon(),
              ),
            )
          : _placeholderIcon(),
    );
  }

  Widget _placeholderIcon() {
    return const Center(
      child: Icon(
        Icons.pets,
        size: 32,
        color: WireframeColors.border,
      ),
    );
  }
}
