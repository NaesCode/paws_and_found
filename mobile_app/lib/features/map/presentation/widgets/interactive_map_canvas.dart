import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/location_constants.dart';
import '../../../../shared/atoms/current_location_button.dart';
import '../../domain/entities/map_report_entity.dart';
import './map_pin_badge.dart';
import './user_location_marker.dart';

/// An interactive geographic map canvas organism built with `flutter_map`.
///
/// Features:
/// - Real-world GIS tile layer with OpenStreetMap standards and policy compliance
/// - Dynamic interactive report pins using the Atomic Design [MapPinBadge]
/// - Device GPS position indicator using [UserLocationMarker]
/// - Full touch gesture support: pan, pinch-to-zoom, fling
/// - Floating GPS current location button in the bottom right
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
  final double bottomOffset;

  const InteractiveMapCanvas({
    super.key,
    this.center = LocationConstants.defaultLocation,
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
    this.bottomOffset = 16.0,
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

        // 2. Floating Current Location Button (Bottom Right)
        if (onRecenterTap != null)
          Positioned(
            bottom: bottomOffset,
            right: 16,
            child: CurrentLocationButton(
              onTap: onRecenterTap,
            ),
          ),
      ],
    );
  }
}
