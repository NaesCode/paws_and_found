import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';
import 'package:paws_and_found/core/theme/wireframe_colors.dart';
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

  const LocationPinPickerSheet({
    super.key,
    required this.initialLocation,
    this.title = 'Pin Location on Animal Map',
    this.subtitle = 'Tap anywhere on the map to set the alert pin',
    this.pinStatus = 'missing',
    this.onLocationConfirmed,
  });

  /// Static helper to display the modal bottom sheet.
  static Future<LatLng?> show({
    required BuildContext context,
    LatLng? initialLocation,
    String title = 'Pin Location on Animal Map',
    String subtitle = 'Tap anywhere on the map to set the alert pin',
    String pinStatus = 'missing',
  }) {
    return showModalBottomSheet<LatLng>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LocationPinPickerSheet(
        initialLocation: initialLocation ?? const LatLng(14.5995, 120.9842),
        title: title,
        subtitle: subtitle,
        pinStatus: pinStatus,
      ),
    );
  }

  @override
  State<LocationPinPickerSheet> createState() => _LocationPinPickerSheetState();
}

class _LocationPinPickerSheetState extends State<LocationPinPickerSheet> {
  late LatLng _currentPin;
  late final MapController _mapController;

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
    setState(() {
      _currentPin = point;
    });
  }

  void _handleRecenter() {
    setState(() {
      _currentPin = widget.initialLocation;
    });
    _mapController.move(widget.initialLocation, 15.5);
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

                // Recenter Button
                Positioned(
                  top: 12,
                  right: 12,
                  child: Material(
                    color: Colors.white,
                    elevation: 3,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: _handleRecenter,
                      child: Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.my_location_rounded,
                          color: AppColors.darkCharcoal,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),

                // Tap Guide Banner at Bottom of Map
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.touch_app_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'Tap anywhere on map to reposition pin',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
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

