import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/location_constants.dart';
import '../../../../core/services/route_direction_service.dart';
import '../../../../core/theme/app_colors.dart';
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
  final List<LatLng> routePoints;
  final MapReportEntity? routeTarget;
  final RouteDirectionResult? activeRoute;
  final double? estimatedRadiusMeters;
  final VoidCallback? onClearRoute;
  final MapController? mapController;
  final ValueChanged<MapReportEntity>? onReportTap;
  final ValueChanged<MapReportEntity>? onReportLongPress;
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
    this.routePoints = const [],
    this.routeTarget,
    this.activeRoute,
    this.estimatedRadiusMeters,
    this.onClearRoute,
    this.mapController,
    this.onReportTap,
    this.onReportLongPress,
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
            minZoom: LocationConstants.minCebuZoom,
            maxZoom: LocationConstants.maxCebuZoom,
            cameraConstraint: CameraConstraint.containCenter(
              bounds: LocationConstants.cebuBounds,
            ),
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

            // Estimated pet movement radius circles around focused pin
            if (routeTarget != null && estimatedRadiusMeters != null)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: LatLng(routeTarget!.latitude, routeTarget!.longitude),
                    radius: estimatedRadiusMeters!,
                    useRadiusInMeter: true,
                    color: AppColors.accentOrange.withValues(alpha: 0.10),
                    borderColor: AppColors.accentOrange.withValues(alpha: 0.45),
                    borderStrokeWidth: 1.8,
                  ),
                  CircleMarker(
                    point: LatLng(routeTarget!.latitude, routeTarget!.longitude),
                    radius: estimatedRadiusMeters! * 0.45,
                    useRadiusInMeter: true,
                    color: AppColors.accentOrange.withValues(alpha: 0.14),
                    borderColor: AppColors.accentOrange.withValues(alpha: 0.35),
                    borderStrokeWidth: 1.2,
                  ),
                ],
              ),

            // Google Maps-style direction suggestion polyline
            if (routePoints.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routePoints,
                    strokeWidth: 7.5,
                    color: const Color(0xFF1D4ED8).withValues(alpha: 0.35),
                  ),
                  Polyline(
                    points: routePoints,
                    strokeWidth: 4.5,
                    color: const Color(0xFF2563EB),
                  ),
                ],
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

                // Render only focused pin during active direction routing, otherwise all pins
                ...(routeTarget != null ? [routeTarget!] : reports).map((report) {
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
                      onLongPress: () => onReportLongPress?.call(report),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),

        // 2. In-Page Route & Estimated Radius Banner (scoped to MapPage only)
        if (routeTarget != null && activeRoute != null)
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(14),
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.directions_rounded,
                        color: Color(0xFF2563EB),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Route to ${routeTarget!.title}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.darkCharcoal,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${activeRoute!.formattedDistance}'
                            '${activeRoute!.formattedDuration != null ? ' • ~${activeRoute!.formattedDuration}' : ''}'
                            '${estimatedRadiusMeters != null ? ' • ~${(estimatedRadiusMeters! / 1000).toStringAsFixed(1)} km area' : ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onClearRoute,
                      icon: const Icon(Icons.close_rounded, size: 18),
                      color: AppColors.textSecondary,
                      tooltip: 'Clear route',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // 3. Floating Current Location Button (Bottom Right)
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
