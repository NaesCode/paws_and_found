import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../features/map/domain/entities/map_report_entity.dart';
import '../atoms/map_pin_badge.dart';
import '../atoms/user_location_marker.dart';

/// An interactive geographic map canvas organism built with `flutter_map`.
///
/// Features:
/// - Real-world GIS tile layer with OpenStreetMap standards and policy compliance
/// - Dynamic interactive report pins using the Atomic Design [MapPinBadge]
/// - Device GPS position indicator using [UserLocationMarker]
/// - Full touch gesture support: pan, pinch-to-zoom, fling
/// - Floating GPS recenter button
///
/// Adheres strictly to Atomic Design: dumb, stateless UI element relying purely
/// on passed properties and callbacks.
class InteractiveMapCanvas extends StatelessWidget {
  final LatLng center;
  final double zoom;
  final List<MapReportEntity> reports;
  final String? selectedReportId;
  final LatLng? userLocation;
  final MapController? mapController;
  final ValueChanged<MapReportEntity>? onReportTap;
  final VoidCallback? onCanvasTap;
  final VoidCallback? onRecenterTap;
  final String tileUrlTemplate;
  final String userAgentPackageName;

  const InteractiveMapCanvas({
    super.key,
    this.center = const LatLng(14.5995, 120.9842),
    this.zoom = 15.0,
    required this.reports,
    this.selectedReportId,
    this.userLocation,
    this.mapController,
    this.onReportTap,
    this.onCanvasTap,
    this.onRecenterTap,
    this.tileUrlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    this.userAgentPackageName = 'com.pawsandfound.mobile_app',
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. The Interactive GIS Map View
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: zoom,
            onTap: (_, _) => onCanvasTap?.call(),
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            // OSM Standard compliant tile layer
            TileLayer(
              urlTemplate: tileUrlTemplate,
              userAgentPackageName: userAgentPackageName,
              maxZoom: 19,
            ),

            // Sighting report markers + User location marker
            MarkerLayer(
              markers: [
                // Render user GPS indicator if available
                if (userLocation != null)
                  Marker(
                    point: userLocation!,
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    child: const UserLocationMarker(),
                  ),

                // Render all animal sightings
                ...reports.map((report) {
                  final isSelected = report.id == selectedReportId;
                  return Marker(
                    point: LatLng(report.latitude, report.longitude),
                    width: isSelected ? 48 : 40,
                    height: isSelected ? 48 : 40,
                    alignment: Alignment.center,
                    child: MapPinBadge(
                      label: report.pinLabel,
                      status: report.status,
                      isSelected: isSelected,
                      onTap: () => onReportTap?.call(report),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),

        // 2. Floating GPS Recenter Button (Top Right)
        if (onRecenterTap != null)
          Positioned(
            top: 16,
            right: 16,
            child: Material(
              color: Colors.white,
              elevation: 3,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onRecenterTap,
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.my_location_rounded,
                    color: Color(0xFF1F2937),
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
