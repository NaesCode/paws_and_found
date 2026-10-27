import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:paws_and_found/core/constants/location_constants.dart';
import 'package:paws_and_found/core/services/location_service.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';
import 'package:paws_and_found/core/theme/wireframe_colors.dart';
import 'package:paws_and_found/shared/atoms/current_location_button.dart';
import 'package:paws_and_found/shared/atoms/drag_handle.dart';
import 'package:paws_and_found/shared/atoms/map_pin_badge.dart';
import 'package:paws_and_found/shared/atoms/paw_button.dart';

/// Interactive modal sheet allowing users to pinpoint an exact geographic
/// location on the Animal Map.
///
/// Features:
/// - Real-world GIS tile map canvas via `flutter_map`
/// - Tap anywhere or drag to place the alert pin
/// - Dynamic coordinates readout display
/// - Re-center button to reset back to initial coordinates
/// - Confirm action returning the chosen [LatLng]
///
/// Adheres strictly to Atomic Design: dumb organism component relying purely on
/// passed properties and callbacks.
class LocationPinPickerSheet extends StatefulWidget {
  final LatLng initialLocation;
  final String title;
  final String subtitle;
  final String pinStatus;
  final ValueChanged<LatLng>? onLocationConfirmed;
  final LocationService? locationService;

  const LocationPinPickerSheet({
    super.key,
    required this.initialLocation,
    this.title = 'Pin Location on Animal Map',
    this.subtitle = 'Tap anywhere on the map to set the alert pin',
    this.pinStatus = 'missing',
    this.onLocationConfirmed,
    this.locationService,
  });

  /// Static helper to display the modal bottom sheet.
  ///
  /// If [initialLocation] is null, queries the user's phone GPS location via [LocationService]
  /// and falls back to [LocationConstants.defaultLocation] if unavailable.
  static Future<LatLng?> show({
    required BuildContext context,
    LatLng? initialLocation,
    String title = 'Pin Location on Animal Map',
    String subtitle = 'Tap anywhere on the map to set the alert pin',
    String pinStatus = 'missing',
    LocationService? locationService,
  }) async {
    LatLng startingLocation;
    if (initialLocation != null) {
      startingLocation = initialLocation;
    } else {
      final service = locationService ?? const GeolocatorLocationService();
      try {
        final pos = await service.getCurrentPosition();
        if (pos != null) {
          startingLocation = LatLng(pos.latitude, pos.longitude);
        } else {
          startingLocation = LocationConstants.defaultLocation;
        }
      } catch (_) {
        startingLocation = LocationConstants.defaultLocation;
      }
    }

    if (!context.mounted) return null;

    return showModalBottomSheet<LatLng>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LocationPinPickerSheet(
        initialLocation: startingLocation,
        title: title,
        subtitle: subtitle,
        pinStatus: pinStatus,
        locationService: locationService,
      ),
    );
  }

  @override
  State<LocationPinPickerSheet> createState() => _LocationPinPickerSheetState();
}

class _LocationPinPickerSheetState extends State<LocationPinPickerSheet> {
  late LatLng _currentPin;
  late final MapController _mapController;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _currentPin = widget.initialLocation;
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _handleMapTap(TapPosition tapPosition, LatLng point) {
    if (!LocationConstants.isWithinCebu(point.latitude, point.longitude)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pins must be placed within Cebu province.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() {
      _currentPin = point;
    });
  }

  Future<void> _handleRecenter() async {
    setState(() {
      _isLocating = true;
    });

    final service = widget.locationService ?? const GeolocatorLocationService();
    try {
      final pos = await service.getCurrentPosition();
      if (!mounted) return;
      if (pos != null) {
        final target = LatLng(pos.latitude, pos.longitude);
        setState(() {
          _currentPin = target;
          _isLocating = false;
        });
        _mapController.move(target, 15.5);
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isLocating = false;
        _currentPin = widget.initialLocation;
      });
      _mapController.move(widget.initialLocation, 15.5);
    }
  }

  void _handleConfirm() {
    widget.onLocationConfirmed?.call(_currentPin);
    Navigator.of(context).pop(_currentPin);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isMissing = widget.pinStatus.toLowerCase() == 'missing';
    final pinLabel = isMissing ? 'M' : (widget.pinStatus.toLowerCase() == 'found' ? 'F' : 'S');

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background1,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: 24 + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DragHandle(),
          const SizedBox(height: 12),

          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isMissing ? AppColors.contrast2 : AppColors.primary).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.pin_drop_rounded,
                  color: isMissing ? AppColors.contrast2 : AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontFamily: 'Nunito Sans',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkCharcoal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        fontFamily: 'Ek Mukta',
                        fontSize: 13,
                        color: AppColors.text3,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.text3),
                onPressed: () => Navigator.of(context).pop(null),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Coordinates Indicator Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.my_location,
                  size: 16,
                  color: isMissing ? AppColors.contrast2 : AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pinned at: ${_currentPin.latitude.toStringAsFixed(5)}° N, ${_currentPin.longitude.toStringAsFixed(5)}° E',
                    style: const TextStyle(
                      fontFamily: 'Nunito Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkCharcoal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Interactive Map Box
          Container(
            height: 280,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: WireframeColors.border, width: 1.2),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentPin,
                    initialZoom: 15.0,
                    minZoom: LocationConstants.minCebuZoom,
                    maxZoom: LocationConstants.maxCebuZoom,
                    cameraConstraint: CameraConstraint.containCenter(
                      bounds: LocationConstants.cebuBounds,
                    ),
                    onTap: _handleMapTap,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.pawsandfound.mobile_app',
                      maxZoom: 19,
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _currentPin,
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          child: MapPinBadge(
                            label: pinLabel,
                            status: widget.pinStatus,
                            isSelected: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Tap Guide Banner at Bottom-Left of Map
                Positioned(
                  left: 12,
                  right: 58,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.touch_app_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Tap map to reposition pin',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Current Location Button at Bottom Right
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: CurrentLocationButton(
                    key: const Key('pin_picker_current_location_button'),
                    size: 38,
                    onTap: _handleRecenter,
                    isLoading: _isLocating,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Actions Row
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: 'Nunito Sans',
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkCharcoal,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: PawButton(
                  text: 'Confirm Pin Location',
                  icon: Icons.check_circle_outline,
                  color: isMissing ? AppColors.contrast2 : AppColors.primary,
                  textColor: Colors.white,
                  onPressed: _handleConfirm,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

