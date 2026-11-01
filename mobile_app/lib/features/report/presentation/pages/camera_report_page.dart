import 'package:paws_and_found/features/feed/data/models/feed_post_model.dart';
import 'package:paws_and_found/features/feed/data/repositories/feed_repository_impl.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:paws_and_found/features/feed/presentation/widgets/feed_card_footer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/location_constants.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/wireframe_colors.dart';
import '../../../../shared/organisms/location_pin_picker_sheet.dart';
import '../../../../core/constants/app_assets.dart';
import '../widgets/ai_match_scanner_card.dart';
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
  final String? threadId;
  final String? threadPetName;
  final String? defaultStatus;

  const CameraReportPage({
    super.key,
    this.repository,
    this.locationService,
    this.showBottomNavPlaceholder = true,
    this.isActiveTab = true,
    this.threadId,
    this.threadPetName,
    this.defaultStatus,
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
    // _controller.fetchDeviceLocation();
    _controller.fetchDeviceLocation().then((_) {
      _controller.reverseGeocodeCurrentCoords(); 
    });

    if (widget.threadId != null) {
      _controller.setThreadContext(
        threadId: widget.threadId,
        petName: widget.threadPetName,
      );
    }
    if (widget.defaultStatus != null && widget.defaultStatus!.isNotEmpty) {
      _controller.setStatus(widget.defaultStatus!);
    }

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
      if (widget.threadId != null) {
      _controller.setThreadContext(
        threadId: widget.threadId,
        petName: widget.threadPetName,
      );
    }
    if (widget.defaultStatus != null && widget.defaultStatus!.isNotEmpty) {
      _controller.setStatus(widget.defaultStatus!);
    }

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
      await _controller.reverseGeocodeCurrentCoords();
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

  Future<void> _handleViewAllCandidates() async {
    final candidates = _controller.aiCandidates;
    if (candidates.isEmpty) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (ctx, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: WireframeColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: WireframeColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: WireframeColors.primaryDark),
                        const SizedBox(width: 8),
                        Text(
                          'AI Visual Matches (${candidates.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: WireframeColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: candidates.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final candidate = candidates[index];
                        final hasPic = candidate.photoUrl.isNotEmpty &&
                            (candidate.photoUrl.startsWith('http://') || candidate.photoUrl.startsWith('https://'));
                        final isSelected = _controller.selectedAiCandidate?.reportId == candidate.reportId;

                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: hasPic
                                  ? Image.network(
                                      candidate.photoUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Image.asset(
                                        AppAssets.petPlaceholder,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Image.asset(AppAssets.petPlaceholder, fit: BoxFit.cover),
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                candidate.petName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: candidate.isHighConfidence
                                      ? const Color(0xFF33691E)
                                      : WireframeColors.primaryDark,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${candidate.similarityPercent}% match',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            '${candidate.species}${candidate.distanceKm != null ? " • ${candidate.distanceKm!.toStringAsFixed(1)} km away" : ""}\nLast seen: ${candidate.lastSeenLocation ?? "Unknown location"}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: WireframeColors.textSecondary),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: Color(0xFF33691E))
                              : ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: WireframeColors.primaryDark,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  onPressed: () {
                                    Navigator.of(modalCtx).pop();
                                    _controller.selectAiCandidate(candidate);
                                  },
                                  child: const Text('Link', style: TextStyle(color: Colors.white, fontSize: 11)),
                                ),
                          onTap: () {
                            Navigator.of(modalCtx).pop();
                            _controller.selectAiCandidate(candidate);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handlePickThread() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (ctx, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: WireframeColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: WireframeColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.link_rounded, color: WireframeColors.primaryDark),
                        SizedBox(width: 8),
                        Text(
                          'Select Missing Pet Thread',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: WireframeColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: FutureBuilder<List<FeedPost>>(
                      future: FeedRepositoryImpl().getGeneralReports('', filterStatus: 'missing'),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: WireframeColors.primaryDark));
                        }
                        final missingReports = snapshot.data ?? [];
                        if (missingReports.isEmpty) {
                          return const Center(
                            child: Text(
                              'No active missing pet reports found.',
                              style: TextStyle(color: WireframeColors.textSecondary),
                            ),
                          );
                        }
                        return ListView.separated(
                          controller: scrollController,
                          itemCount: missingReports.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final pet = missingReports[index];
                            final hasPic = pet.imageUrl.isNotEmpty &&
                                (pet.imageUrl.startsWith('http://') || pet.imageUrl.startsWith('https://'));
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: WireframeColors.surfaceSecondary,
                                backgroundImage: hasPic ? NetworkImage(pet.imageUrl) : null,
                                child: hasPic
                                    ? null
                                    : const Icon(Icons.pets, color: WireframeColors.primaryDark),
                              ),
                              title: Text(
                                pet.petName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                '${pet.species} • ${pet.location.isNotEmpty ? pet.location : "Cebu"}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: const Icon(Icons.chevron_right, size: 20),
                              onTap: () {
                                Navigator.of(modalCtx).pop();
                                _controller.setThreadContext(
                                  threadId: pet.id,
                                  petName: pet.petName,
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
            TextButton.icon(
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('Copy Link'),
              onPressed: () {
                final reportId = _controller.successReportId ?? '';
                Clipboard.setData(ClipboardData(text: 'https://pawsandfound.org/report/$reportId'));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sighting link copied to clipboard!')),
                );
              },
            ),
            if (_controller.linkedThreadId != null)
              TextButton.icon(
                icon: const Icon(Icons.forum_outlined, size: 16),
                label: const Text('Open Thread'),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  showFeedCommentsModal(
                    context,
                    reportId: _controller.linkedThreadId,
                    petName: _controller.linkedThreadPetName,
                  );
                },
              ),
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

              // AI Visual Pre-Match Scanner / Thread Link
              if (_controller.selectedImageBytes != null)
                AiMatchScannerCard(
                  isScanning: _controller.isScanningAi,
                  candidates: _controller.aiCandidates,
                  selectedCandidate: _controller.selectedAiCandidate,
                  onSelectCandidate: _controller.selectAiCandidate,
                  onClearSelection: _controller.clearAiCandidate,
                  onViewAllCandidates: _handleViewAllCandidates,
                  onManualSearch: _handlePickThread,
                )
              else if (_controller.linkedThreadId != null)
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: WireframeColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: WireframeColors.primaryDark, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.link_rounded, size: 22, color: WireframeColors.primaryDark),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LINKED TO PET REPORT: ${(_controller.linkedThreadPetName ?? "MISSING PET").toUpperCase()}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: WireframeColors.primaryDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'This sighting will be linked to the missing pet report and sightings dashboard.',
                              style: TextStyle(
                                fontSize: 11,
                                color: WireframeColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: WireframeColors.textSecondary),
                        onPressed: _controller.clearThreadContext,
                        tooltip: 'Unlink from report',
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                )
              else
                Padding(
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
                      'Link sighting to an existing Missing Pet report (Optional)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    onPressed: _handlePickThread,
                  ),
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
                onAnimalTypeChanged: _controller.setAnimalType,
                onStatusChanged: _controller.setStatus,
                onToggleGps: _controller.toggleGps,
                onPinOnMap: _handlePinOnMap,
                onSubmit: _handleSubmit,
                resolvedLocationName: _controller.geocodedAddress,
                geocodeAddress: _controller.geocodedAddress,
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
