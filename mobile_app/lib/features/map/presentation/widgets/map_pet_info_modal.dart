import 'package:flutter/material.dart';
import '../../../../core/theme/wireframe_colors.dart';
import '../../../../shared/atoms/wireframe_status_badge.dart';
import '../../../../shared/atoms/wireframe_tag.dart';
import '../../domain/entities/map_report_entity.dart';

/// A wireframe popup dialog modal displaying comprehensive details
/// for an animal pin tapped on the Community Animal Map.
///
/// Features:
/// - Floating dialog popup with barrier dismissal (tap outside to exit)
/// - Top-right "X" close button
/// - Animal photo frame with wireframe placeholder fallback
/// - Status badge (MISSING, STRAY, FOUND)
/// - Animal title, species, and attribute tags
/// - Geolocation info: area name, GPS coordinates, distance from user
/// - Recency timestamp
/// - Full multiline sighting / last-seen notes
/// - Placeholder action buttons: "Report Sighting", "Contact", "Share"
class MapPetInfoModal extends StatelessWidget {
  final MapReportEntity report;
  final VoidCallback? onReportSighting;
  final VoidCallback? onContact;
  final VoidCallback? onShare;

  const MapPetInfoModal({
    super.key,
    required this.report,
    this.onReportSighting,
    this.onContact,
    this.onShare,
  });

  /// Displays the modal as a centered dismissible popup dialog.
  static Future<void> show({
    required BuildContext context,
    required MapReportEntity report,
    VoidCallback? onReportSighting,
    VoidCallback? onContact,
    VoidCallback? onShare,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => MapPetInfoModal(
        report: report,
        onReportSighting: onReportSighting,
        onContact: onContact,
        onShare: onShare,
      ),
    );
  }

  void _handlePlaceholderAction(BuildContext context, String actionName, VoidCallback? callback) {
    if (callback != null) {
      callback();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$actionName placeholder tapped'),
          backgroundColor: WireframeColors.primaryDark,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final double maxDialogHeight = mediaQuery.size.height * 0.85;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: maxDialogHeight,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: WireframeColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: WireframeColors.border, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Bar with Close Button
              _buildTopBar(context),

              // Scrollable Details Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Photo Header
                      _buildPhotoSection(),
                      const SizedBox(height: 14),

                      // Title & Status Badge Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  report.title,
                                  style: const TextStyle(
                                    color: WireframeColors.textPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  report.animalType,
                                  style: const TextStyle(
                                    color: WireframeColors.textSecondary,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          WireframeStatusBadge(
                            status: report.status,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          ),
                        ],
                      ),

                      // Attribute Tags
                      if (report.tags.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: report.tags.map((tag) => WireframeTag(label: tag)).toList(),
                        ),
                      ],

                      const SizedBox(height: 14),
                      const Divider(color: WireframeColors.divider, height: 1),
                      const SizedBox(height: 14),

                      // Geolocation Card
                      _buildLocationSection(),

                      const SizedBox(height: 14),
                      const Divider(color: WireframeColors.divider, height: 1),
                      const SizedBox(height: 14),

                      // Sighting / Description Notes
                      _buildDescriptionSection(),

                      const SizedBox(height: 20),

                      // Placeholder Action Buttons
                      _buildActionButtons(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 10, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Icon(
                Icons.pets_rounded,
                size: 18,
                color: WireframeColors.textSecondary,
              ),
              SizedBox(width: 6),
              Text(
                'Animal Details',
                style: TextStyle(
                  color: WireframeColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          IconButton(
            key: const Key('map_pet_info_modal_close_button'),
            icon: const Icon(
              Icons.close_rounded,
              color: WireframeColors.textPrimary,
              size: 22,
            ),
            splashRadius: 20,
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Container(
      height: 170,
      width: double.infinity,
      decoration: BoxDecoration(
        color: WireframeColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WireframeColors.border, width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: report.photoUrl != null && report.photoUrl!.isNotEmpty
          ? Image.network(
              report.photoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildPhotoPlaceholder(),
            )
          : _buildPhotoPlaceholder(),
    );
  }

  Widget _buildPhotoPlaceholder() {
    return Container(
      color: WireframeColors.surfaceSecondary,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.photo_camera_outlined,
            size: 38,
            color: WireframeColors.border,
          ),
          SizedBox(height: 6),
          Text(
            'Photo Placeholder',
            style: TextStyle(
              color: WireframeColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    final distanceText = report.distanceMeters != null
        ? report.distanceMeters! >= 1000
            ? '${(report.distanceMeters! / 1000).toStringAsFixed(1)} km away'
            : '${report.distanceMeters!.round()} m away'
        : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WireframeColors.surfaceTertiary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WireframeColors.borderLight, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: WireframeColors.textPrimary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.locationName,
                      style: const TextStyle(
                        color: WireframeColors.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${report.latitude.toStringAsFixed(4)}° N, ${report.longitude.toStringAsFixed(4)}° E${distanceText != null ? ' • $distanceText' : ''}',
                      style: const TextStyle(
                        color: WireframeColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 16,
                color: WireframeColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Reported ${report.formattedTimeAgo}',
                style: const TextStyle(
                  color: WireframeColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Last Seen / Sighting Details',
          style: TextStyle(
            color: WireframeColors.textSecondary,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: WireframeColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: WireframeColors.borderLight, width: 1.0),
          ),
          child: Text(
            report.description.isNotEmpty
                ? report.description
                : 'No additional sighting details provided.',
            style: const TextStyle(
              color: WireframeColors.textPrimary,
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary Action: "I Spotted This Pet" / "Report Sighting"
        ElevatedButton.icon(
          key: const Key('modal_action_spotted_button'),
          onPressed: () => _handlePlaceholderAction(context, 'Report Sighting', onReportSighting),
          icon: const Icon(Icons.camera_alt_outlined, size: 18, color: Colors.white),
          label: const Text(
            'I Spotted This Animal',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: WireframeColors.primaryDark,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Secondary Actions Row: "Contact" and "Share"
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('modal_action_contact_button'),
                onPressed: () => _handlePlaceholderAction(context, 'Contact', onContact),
                icon: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 16,
                  color: WireframeColors.textPrimary,
                ),
                label: const Text(
                  'Contact',
                  style: TextStyle(
                    color: WireframeColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: WireframeColors.border, width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('modal_action_share_button'),
                onPressed: () => _handlePlaceholderAction(context, 'Share', onShare),
                icon: const Icon(
                  Icons.share_outlined,
                  size: 16,
                  color: WireframeColors.textPrimary,
                ),
                label: const Text(
                  'Share',
                  style: TextStyle(
                    color: WireframeColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: WireframeColors.border, width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
