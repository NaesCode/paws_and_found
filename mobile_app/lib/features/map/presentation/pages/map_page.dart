import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/wireframe_colors.dart';
import '../../../../shared/organisms/custom_app_bar.dart';
import '../widgets/interactive_map_canvas.dart';
import '../widgets/map_filter_bar.dart';
import '../widgets/map_legend.dart';
import '../widgets/map_report_card.dart';
import '../widgets/map_screen_template.dart';
import '../../domain/entities/map_filter_type.dart';
import '../../domain/repositories/map_repository.dart';
import '../providers/map_controller.dart';

/// Community Animal Map screen (Interactive GIS Implementation).
///
/// Implements SDD Section 6.1 (3) & Section 6.2 (03 - Community Map):
/// - Real-world GIS Map Interface Canvas via `flutter_map`
/// - Status-differentiated Map Markers ('M' Missing, 'S' Stray, 'F' Found)
/// - Discovery Filter Sub-menu ("All", "For You", "Animal Type")
/// - Floating Report Details Card for targeted animal sightings
/// - Pin status legend
/// - Finalized [CustomAppBar] navigation shell integration
///
/// Adheres strictly to Atomic Design (using lib/shared/ components)
/// and Clean Architecture (using MapController and MapRepository).
class MapPage extends StatefulWidget {
  final MapRepository? repository;
  final bool showBottomNavPlaceholder;

  const MapPage({
    super.key,
    this.repository,
    this.showBottomNavPlaceholder = true,
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late final MapController _controller;
  late final fmap.MapController _fmapController;

  @override
  void initState() {
    super.initState();
    _fmapController = fmap.MapController();
    _controller = MapController(repository: widget.repository);
    _controller.addListener(_onControllerUpdate);
    _controller.loadReports();
    // Non-blocking fetch of device GPS location
    _controller.fetchUserLocation();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    _fmapController.dispose();
    super.dispose();
  }

  Future<void> _handleRecenter() async {
    await _controller.fetchUserLocation();
    if (_controller.userLocation != null) {
      _fmapController.move(_controller.userLocation!, 15.5);
    } else {
      _controller.recenterMap();
      _fmapController.move(_controller.mapCenter, 15.0);
    }
  }

  void _showSpeciesFilterDialog() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: WireframeColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Text(
                    'Filter by Animal Type',
                    style: TextStyle(
                      color: WireframeColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Divider(color: WireframeColors.borderLight),
                ListTile(
                  leading: const Icon(Icons.clear_all_rounded, color: WireframeColors.primaryDark),
                  title: const Text('All Animal Types'),
                  selected: _controller.selectedAnimalType == null,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _controller.setAnimalType(null);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.pets, color: WireframeColors.primaryDark),
                  title: const Text('Canine (Dogs)'),
                  selected: _controller.selectedAnimalType == 'Canine',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _controller.setAnimalType('Canine');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.pets, color: WireframeColors.secondarySlate),
                  title: const Text('Feline (Cats)'),
                  selected: _controller.selectedAnimalType == 'Feline',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _controller.setAnimalType('Feline');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.category_outlined, color: WireframeColors.textSecondary),
                  title: const Text('Other Animals'),
                  selected: _controller.selectedAnimalType == 'Other',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _controller.setAnimalType('Other');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = _controller.selectedReport;

    return MapScreenTemplate(
      // 1. Header: "Animal Map" + Re-center target button
      header: _buildHeader(),

      // 2. Filter Bar: "All", "For You", "Animal Type ▼"
      filterBar: MapFilterBar(
        selectedFilter: _controller.currentFilter == MapFilterType.all
            ? 'all'
            : 'for_you',
        selectedAnimalType: _controller.selectedAnimalType,
        onFilterSelected: (filter) {
          _controller.setFilter(
            filter == 'all' ? MapFilterType.all : MapFilterType.forYou,
          );
        },
        onAnimalTypePressed: _showSpeciesFilterDialog,
      ),

      // 3. Map Canvas: Real-world interactive GIS map with custom pin markers
      mapCanvas: InteractiveMapCanvas(
        center: _controller.mapCenter,
        reports: _controller.reports,
        selectedReportId: selected?.id,
        userLocation: _controller.userLocation,
        mapController: _fmapController,
        onReportTap: (report) {
          _controller.selectReport(report);
          _fmapController.move(
            LatLng(report.latitude, report.longitude),
            _fmapController.camera.zoom,
          );
        },
        onCanvasTap: _controller.clearSelection,
        onRecenterTap: _handleRecenter,
      ),

      // 4. Floating Report Detail Card
      reportCard: selected != null
          ? MapReportCard(
              title: selected.title,
              subtitle: selected.subtitle,
              status: selected.status,
              tags: selected.tags,
              photoUrl: selected.photoUrl,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Selected ${selected.title} (${selected.status.toUpperCase()})',
                    ),
                    backgroundColor: WireframeColors.primaryDark,
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            )
          : null,

      // 5. Pin status legend at the bottom
      legend: const MapLegend(),

      // 6. Bottom navigation bar (CustomAppBar)
      bottomNavigationBar: widget.showBottomNavPlaceholder
          ? CustomAppBar(
              currentIndex: 0,
              onTabSelected: (index) {
                switch (index) {
                  case 0:
                    // Already on Map
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
                    context.go('/camera');
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Screen Title
          const Text(
            'Animal Map',
            style: TextStyle(
              color: WireframeColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),

          // Re-center target button (circle inside rounded square)
          InkWell(
            onTap: _handleRecenter,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: WireframeColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: WireframeColors.border,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: WireframeColors.secondarySlate,
                    width: 2.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
