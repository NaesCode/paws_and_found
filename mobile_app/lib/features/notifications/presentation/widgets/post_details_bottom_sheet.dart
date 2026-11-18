import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paws_and_found/core/constants/location_constants.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';
import 'package:paws_and_found/features/map/data/models/map_report_model.dart';

import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

/// Modal bottom sheet that displays complete details for a post referenced
/// in an in-app notification, allowing users to view the post directly.
class PostDetailsBottomSheet extends StatefulWidget {
  final AppNotification notification;
  final NotificationRepository repository;
  final void Function(String reportId, double? lat, double? lng)? onViewOnMap;

  const PostDetailsBottomSheet({
    super.key,
    required this.notification,
    required this.repository,
    this.onViewOnMap,
  });

  /// Static helper to display the sheet.
  static Future<void> show({
    required BuildContext context,
    required AppNotification notification,
    required NotificationRepository repository,
    void Function(String reportId, double? lat, double? lng)? onViewOnMap,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PostDetailsBottomSheet(
        notification: notification,
        repository: repository,
        onViewOnMap: onViewOnMap,
      ),
    );
  }

  @override
  State<PostDetailsBottomSheet> createState() => _PostDetailsBottomSheetState();
}

class _PostDetailsBottomSheetState extends State<PostDetailsBottomSheet> {
  late Future<Map<String, dynamic>?> _postFuture;

  @override
  void initState() {
    super.initState();
    _postFuture =
        widget.repository.getPostDetailsForNotification(widget.notification);
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'missing':
        return const Color(0xFFDC2626);
      case 'stray':
      case 'spotted':
        return AppColors.accentOrange;
      case 'found':
      case 'safe':
        return const Color(0xFF059669);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.88;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Main Scrollable Content
          Expanded(
            child: FutureBuilder<Map<String, dynamic>?>(
              future: _postFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  );
                }

                if (snapshot.hasError || snapshot.data == null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 48, color: AppColors.text3),
                          const SizedBox(height: 12),
                          const Text(
                            'Post is no longer available.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkCharcoal,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'This report has been withdrawn, removed, or resolved.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: AppColors.text3),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                            ),
                            child: const Text('Close',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final post = snapshot.data!;
                final title = post['title'] as String? ?? 'Animal Sighting';
                final animalType = post['animalType'] as String? ?? 'Animal';
                final status = (post['status'] as String? ?? 'missing').toUpperCase();
                final description = post['description'] as String? ?? '';
                final locationName = post['locationName'] as String? ?? 'Cebu Community';
                final reporterName = post['reporterName'] as String? ?? 'Community Member';
                final photoUrl = post['photoUrl'] as String? ?? '';
                final double? lat = (post['latitude'] as num?)?.toDouble();
                final double? lng = (post['longitude'] as num?)?.toDouble();
                final rawId = post['id'] as String? ?? '';
                final isFlagged =
                    (post['moderationStatus'] as String? ?? '').toLowerCase() == 'flagged';
                final moderationNotes = post['moderationNotes'] as String?;

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Row: Status badge and Close button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statusColor(status).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: _statusColor(status), width: 1),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: _statusColor(status),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: AppColors.darkCharcoal),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Post Image or Clean Placeholder
                      _buildPictureFrame(
                        context: context,
                        photoUrl: photoUrl,
                        title: title,
                        animalType: animalType,
                      ),
                      const SizedBox(height: 14),

                      // Title & Species
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkCharcoal,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Category: $animalType',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Reporter & Timestamp card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.primary,
                              child: Icon(Icons.person,
                                  color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Reported by $reporterName',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.darkCharcoal,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    widget.notification.message,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.text3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Location Row
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              size: 18, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              locationName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.darkCharcoal,
                              ),
                            ),
                          ),
                          if (lat != null && lng != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${lat.toStringAsFixed(3)}°, ${lng.toStringAsFixed(3)}°',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF0369A1),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Flagged / Moderation Callout (if applicable)
                      if (isFlagged ||
                          (moderationNotes != null &&
                              moderationNotes.isNotEmpty)) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFCD34D)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.shield_outlined,
                                      color: Color(0xFFB45309), size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Moderator Feedback & Action Required',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF92400E),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                moderationNotes ??
                                    'This post was flagged by AI content moderation. Please review the details.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF78350F),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Description Section
                      const Text(
                        'Full Description',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text3,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          description.isNotEmpty
                              ? description
                              : 'No description provided.',
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: AppColors.darkCharcoal,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Interactive "View on Map" Button
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          final cleanId = rawId.replaceFirst('#', '');

                          final model = MapReportModel(
                            id: cleanId.isNotEmpty
                                ? cleanId
                                : 'report-${DateTime.now().millisecondsSinceEpoch}',
                            reporterId: post['reporterId']?.toString() ??
                                'community-reporter',
                            petId: post['petId']?.toString(),
                            title: title,
                            animalType: animalType,
                            description: description,
                            status: status.toLowerCase(),
                            locationName: locationName,
                            latitude: lat ?? LocationConstants.defaultLatitude,
                            longitude: lng ?? LocationConstants.defaultLongitude,
                            normalizedX: 0.5,
                            normalizedY: 0.5,
                            photoUrl: photoUrl.isNotEmpty ? photoUrl : null,
                            createdAt: post['createdAt'] is DateTime
                                ? post['createdAt'] as DateTime
                                : DateTime.now(),
                            tags: [animalType, status.toUpperCase()],
                          );
                          MapReportModel.addReport(model);

                          if (widget.onViewOnMap != null) {
                            widget.onViewOnMap!(cleanId, lat, lng);
                          } else {
                            _navigateToMap(context, cleanId, lat, lng);
                          }
                        },
                        icon: const Icon(Icons.map_rounded, size: 18),
                        label: const Text(
                          'View on Community Map',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Close Button
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.darkCharcoal,
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToMap(
      BuildContext context, String reportId, double? lat, double? lng) {
    try {
      final cleanId = reportId.replaceFirst('#', '');
      String query = 'reportId=$cleanId';
      if (lat != null && lng != null) {
        query += '&lat=$lat&lng=$lng';
      }
      context.push('/map?$query');
    } catch (_) {
      // Fallback if router not in widget tree
    }
  }

  Widget _buildPictureFrame({
    required BuildContext context,
    required String photoUrl,
    required String title,
    required String animalType,
  }) {
    final hasValidPhoto = photoUrl.isNotEmpty &&
        (photoUrl.startsWith('http://') ||
            photoUrl.startsWith('https://') ||
            photoUrl.startsWith('assets/'));

    if (!hasValidPhoto) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 220,
          width: double.infinity,
          color: const Color(0xFFF1F5F9),
          child: _placeholderImage(animalType: animalType),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 240,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        ),
        child: GestureDetector(
          onTap: () => _openFullScreenPhoto(context, photoUrl, title),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Ambient blurred background layer that gracefully fills the frame
              ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: _buildPhotoImage(photoUrl, fit: BoxFit.cover),
              ),
              // Soft dark overlay to enhance contrast and focus
              Container(
                color: Colors.black.withValues(alpha: 0.32),
              ),
              // Crisp, full, non-truncated photo centered without any cropping
              Center(
                child: _buildPhotoImage(
                  photoUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) =>
                      _placeholderImage(animalType: animalType),
                ),
              ),
              // Tap to expand / zoom badge
              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 0.8,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.zoom_in_rounded, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Full Photo',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
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

  Widget _buildPhotoImage(
    String url, {
    required BoxFit fit,
    Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
  }) {
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: fit,
        errorBuilder: errorBuilder ?? (_, _, _) => const SizedBox.shrink(),
      );
    }
    return Image.network(
      url,
      fit: fit,
      errorBuilder: errorBuilder ?? (_, _, _) => const SizedBox.shrink(),
    );
  }

  void _openFullScreenPhoto(BuildContext context, String url, String title) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (dialogCtx) => Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: Center(
                child: _buildPhotoImage(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.broken_image_rounded,
                    color: Colors.white70,
                    size: 48,
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(dialogCtx).padding.top + 12,
              right: 16,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(dialogCtx).padding.top + 18,
              left: 20,
              right: 70,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  shadows: [
                    Shadow(
                      color: Colors.black87,
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage({String? animalType}) {
    final type = animalType ?? 'Animal';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.pets_rounded,
              size: 38,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'No Photo Available',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.darkCharcoal,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$type Sighting Report',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: AppColors.text3,
            ),
          ),
        ],
      ),
    );
  }
}
