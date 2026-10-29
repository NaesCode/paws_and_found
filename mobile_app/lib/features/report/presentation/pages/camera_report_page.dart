import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/location_constants.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/wireframe_colors.dart';
import '../../../../shared/organisms/location_pin_picker_sheet.dart';
import '../widgets/camera_viewfinder_placeholder.dart';
import '../widgets/create_report_form.dart';
import '../../../../shared/organisms/custom_app_bar.dart';
import '../../domain/repositories/report_repository.dart';
import '../providers/camera_report_controller.dart';

/// Camera and Animal Report Creation screen (SDD Screen 05).
///
/// Features:
/// - Real-time in-app camera viewfinder preview with framing brackets & gallery selector
/// - Instant shutter snap with fallback to system camera/mock
/// - Animal Type ("Canine", "Feline", "Other") & Status ("Stray", "Missing", "Found")
/// - Description input block
/// - Auto GPS via [LocationService] & Date/Time fields
/// - Interactive map pin placement for missing animals via [LocationPinPickerSheet]
/// - "Submit Report" button with immediate relations to the Community Map & AI Recovery Pipeline
/// - Wireframe bottom navigation bar with active Camera indicator
class CameraReportPage extends StatefulWidget {
  final ReportRepository? repository;
  final LocationService? locationService;
  final bool showBottomNavPlaceholder;
  final bool isActiveTab;

  const CameraReportPage({
    super.key,
    this.repository,
    this.locationService,
    this.showBottomNavPlaceholder = true,
    this.isActiveTab = true,
  });

  @override
  State<CameraReportPage> createState() => _CameraReportPageState();
}

class _CameraReportPageState extends State<CameraReportPage> with WidgetsBindingObserver {
  late final CameraReportController _controller;
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isTakingPicture = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = CameraReportController(
      repository: widget.repository,
      locationService: widget.locationService,
    );
    _controller.addListener(_onControllerUpdate);
    _controller.fetchDeviceLocation();

    if (widget.isActiveTab) {
      _initLiveCamera();
    }
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _initLiveCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      // Prefer rear camera for photographing animals
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _isCameraInitialized = true;
      });
    } catch (e) {
      debugPrint('[CameraReportPage] Live camera unavailable: $e');
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant CameraReportPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActiveTab != widget.isActiveTab) {
      if (widget.isActiveTab) {
        if (_cameraController == null) {
          _initLiveCamera();
        } else if (_cameraController!.value.isInitialized) {
          try {
            _cameraController?.resumePreview();
          } catch (_) {}
        }
      } else {
        if (_cameraController != null && _cameraController!.value.isInitialized) {
          try {
            _cameraController?.pausePreview();
          } catch (_) {}
        }
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final camera = _cameraController;
    if (camera == null || !camera.value.isInitialized) return;

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _cameraController?.dispose();
      _cameraController = null;
      if (mounted) setState(() => _isCameraInitialized = false);
    } else if (state == AppLifecycleState.resumed && widget.isActiveTab) {
      _initLiveCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleCaptureTap() async {
    if (_isCameraInitialized && _cameraController != null && _cameraController!.value.isInitialized) {
      try {
        setState(() => _isTakingPicture = true);
        final XFile photo = await _cameraController!.takePicture();
        final bytes = await photo.readAsBytes();
        _controller.setImageData(bytes, photo.path);
      } catch (e) {
        debugPrint('[CameraReportPage] In-app snapshot failed, falling back to system capture: $e');
        await _controller.capturePhoto();
      } finally {
        if (mounted) setState(() => _isTakingPicture = false);
      }
    } else {
      await _controller.capturePhoto();
    }
  }

  Future<void> _handlePinOnMap() async {
    final double? defaultLat = _controller.pinnedLat ?? _controller.deviceLat;
    final double? defaultLng = _controller.pinnedLng ?? _controller.deviceLng;
    final LatLng? initial = (defaultLat != null && defaultLng != null)
        ? LatLng(defaultLat, defaultLng)
        : null;

    final LatLng? picked = await LocationPinPickerSheet.show(
      context: context,
      initialLocation: initial,
      pinStatus: _controller.status,
      title: 'Pin ${_controller.status} Animal on Map',
      subtitle: 'Tap anywhere on the map to set the exact sighting or missing pin',
      locationService: _controller.locationService,
    );

    if (picked != null) {
      _controller.setPinnedLocation(picked.latitude, picked.longitude);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pin updated: ${picked.latitude.toStringAsFixed(4)}° N, ${picked.longitude.toStringAsFixed(4)}° E',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: WireframeColors.primaryDark,
          ),
        );
      }
    }
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
                      '• Pinned to Community Animal Map\n• Queued for AI Image Matching engine\n• Logged in User Contribution History',
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
                final lat = _controller.pinnedLat ?? _controller.deviceLat ?? LocationConstants.defaultLatitude;
                final lng = _controller.pinnedLng ?? _controller.deviceLng ?? LocationConstants.defaultLongitude;
                final reportId = _controller.successReportId ?? '';
                context.go('/map?reportId=$reportId&lat=$lat&lng=$lng');
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
    Widget? livePreview;
    if (_isCameraInitialized && _cameraController != null && _cameraController!.value.isInitialized) {
      livePreview = SizedBox(
        width: _cameraController!.value.previewSize?.height ?? 100,
        height: _cameraController!.value.previewSize?.width ?? 100,
        child: CameraPreview(_cameraController!),
      );
    }

    return Scaffold(
      backgroundColor: WireframeColors.background,
      body: SafeArea(
        bottom: widget.showBottomNavPlaceholder == false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Live Camera Viewfinder Canvas
              CameraViewfinderPlaceholder(
                height: 270,
                imageBytes: _controller.selectedImageBytes,
                cameraPreview: livePreview,
                isCameraInitialized: _isCameraInitialized,
                isTakingPicture: _isTakingPicture,
                onCaptureTap: _handleCaptureTap,
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
                pinnedLat: _controller.pinnedLat,
                pinnedLng: _controller.pinnedLng,
                deviceLat: _controller.deviceLat,
                deviceLng: _controller.deviceLng,
                resolvedLocationName: _controller.resolvedLocationName,
                onAnimalTypeChanged: _controller.setAnimalType,
                onStatusChanged: _controller.setStatus,
                onToggleGps: _controller.toggleGps,
                onPinOnMap: _handlePinOnMap,
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
                    context.go('/home');
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
