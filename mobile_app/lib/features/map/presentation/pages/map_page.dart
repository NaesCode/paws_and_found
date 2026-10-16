import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/wireframe_colors.dart';
import '../../../../shared/molecules/map_filter_bar.dart';
import '../../../../shared/molecules/map_legend.dart';
import '../../../../shared/organisms/map_placeholder_canvas.dart';
import '../../../../shared/organisms/map_report_card.dart';
import '../../../../shared/organisms/wireframe_bottom_nav_bar.dart';
import '../../../../shared/templates/map_screen_template.dart';
import '../../domain/entities/map_filter_type.dart';
import '../../domain/repositories/map_repository.dart';
import '../providers/map_controller.dart';

/// Community Animal Map screen (Wireframe Implementation).
///
/// Implements SDD Section 6.1 (3) & Section 6.2 (03 - Community Map):
/// - Geographic Map Interface Canvas (interactive placeholder)
/// - Status-differentiated Map Markers ('M' Missing, 'S' Stray, 'F' Found)
/// - Discovery Filter Sub-menu ("All", "For You", "Animal Type")
/// - Floating Report Details Card for targeted animal sightings
/// - Pin status legend
/// - Wireframe bottom navigation bar placeholder
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

  @override
  void initState() {
    super.initState();
    _controller = MapController(repository: widget.repository);
    _controller.addListener(_onControllerUpdate);
    _controller.loadReports();
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

    // Convert domain entities to canvas pins
    final canvasPins = _controller.reports.map((r) {
      return CanvasPinData(
        id: r.id,
        label: r.pinLabel,
        status: r.status,
        normalizedX: r.normalizedX,
        normalizedY: r.normalizedY,
      );
    }).toList();

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

      // 3. Map Canvas: Grid linework + interactive pins
      mapCanvas: MapPlaceholderCanvas(
        pins: canvasPins,
        selectedPinId: selected?.id,
        onPinTap: _controller.selectReportById,
        onCanvasTap: () {
          // Keep current selection or allow interaction
        },
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

      // 6. Bottom navigation bar placeholder
      bottomNavigationBar: widget.showBottomNavPlaceholder
          ? WireframeBottomNavBar(
              currentIndex: 0,
              onTap: (index) {
                switch (index) {
                  case 0:
                    // Currently on Map
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Camera & Sighting Report coming soon!'),
                        duration: Duration(seconds: 1),
                      ),
                    );
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
            onTap: _controller.recenterMap,
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
