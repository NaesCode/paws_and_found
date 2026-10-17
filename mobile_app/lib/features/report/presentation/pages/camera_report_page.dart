import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/wireframe_colors.dart';
import '../../../../shared/molecules/camera_viewfinder_placeholder.dart';
import '../../../../shared/organisms/create_report_form.dart';
import '../../../../shared/organisms/custom_app_bar.dart';
import '../../domain/repositories/report_repository.dart';
import '../providers/camera_report_controller.dart';

/// Camera and Animal Report Creation screen (SDD Screen 05).
///
/// Features:
/// - Native viewfinder canvas placeholder with framing brackets & gallery selector
/// - Animal Type ("Canine", "Feline", "Other") & Status ("Stray", "Missing", "Found")
/// - Description input block
/// - Auto GPS & Date/Time fields
/// - "Submit Report" button with immediate relations to the Community Map & AI Recovery Pipeline
/// - Wireframe bottom navigation bar with active Camera indicator
class CameraReportPage extends StatefulWidget {
  final ReportRepository? repository;
  final bool showBottomNavPlaceholder;

  const CameraReportPage({
    super.key,
    this.repository,
    this.showBottomNavPlaceholder = true,
  });

  @override
  State<CameraReportPage> createState() => _CameraReportPageState();
}

class _CameraReportPageState extends State<CameraReportPage> {
  late final CameraReportController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CameraReportController(repository: widget.repository);
    _controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final success = await _controller.submitReport();
    if (!mounted) return;

    if (success) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: WireframeColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: WireframeColors.primaryDark),
              SizedBox(width: 8),
              Text(
                'Report Submitted',
                style: TextStyle(
                  color: WireframeColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your sighting report for a ${_controller.animalType} (${_controller.status.toUpperCase()}) has been registered.',
                style: const TextStyle(color: WireframeColors.textSecondary, fontSize: 13.5),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: WireframeColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• Added marker to Community Animal Map\n• Queued for AI Image Matching engine\n• Logged in User Contribution History',
                      style: TextStyle(color: WireframeColors.textPrimary, fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Stay Here'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: WireframeColors.primaryDark,
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                context.go('/map');
              },
              child: const Text('View on Map', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.errorMessage ?? 'Submission failed'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WireframeColors.background,
      body: SafeArea(
        bottom: widget.showBottomNavPlaceholder == false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Camera Viewfinder Canvas Placeholder
              CameraViewfinderPlaceholder(
                height: 270,
                imageBytes: _controller.selectedImageBytes,
                onCaptureTap: _controller.capturePhoto,
                onGalleryTap: _controller.pickFromGallery,
                onRetakeTap: _controller.clearPhoto,
              ),

              // 2. "CREATE REPORT" Form Block
              CreateReportForm(
                animalType: _controller.animalType,
                status: _controller.status,
                descriptionController: _controller.descriptionController,
                dateTimeString: _controller.formattedDateTime,
                isGpsAuto: _controller.isGpsAuto,
                isLoading: _controller.isSubmitting,
                onAnimalTypeChanged: _controller.setAnimalType,
                onStatusChanged: _controller.setStatus,
                onToggleGps: _controller.toggleGps,
                onSubmit: _handleSubmit,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: widget.showBottomNavPlaceholder
          ? CustomAppBar(
              currentIndex: 2, // Camera is active (highlighted pill)
              onTabSelected: (index) {
                switch (index) {
                  case 0:
                    context.go('/map');
                    break;
                  case 1:
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Feed (Reports) coming in the next sprint!'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                    break;
                  case 2:
                    // Already on Camera & Report
                    break;
                  case 3:
                    context.go('/profile');
                    break;
                  case 4:
                    context.go('/notifications');
                    break;
                }
              },
            )
          : null,
    );
  }
}
