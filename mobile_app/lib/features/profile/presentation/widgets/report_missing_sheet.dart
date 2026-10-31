import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/location_constants.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/atoms/drag_handle.dart';
import '../../../../shared/atoms/paw_button.dart';
import '../../../../shared/atoms/paw_text_field.dart';
import '../../../../shared/organisms/location_pin_picker_sheet.dart';
import '../../domain/entities/pet.dart';

/// Result data returned when the user submits a missing pet report.
class ReportMissingResult {
  final double latitude;
  final double longitude;
  final String note;

  const ReportMissingResult({
    required this.latitude,
    required this.longitude,
    required this.note,
  });
}

/// Modal bottom sheet allowing users to report a pet as missing.
///
/// Features:
/// - Automatically queries [LocationService] for current device GPS coordinates.
/// - Allows interactive map pinning via [LocationPinPickerSheet]
/// - Displays coordinates with a retry option if GPS hardware or permissions are denied.
/// - Allows inputting an optional last-seen description/note.
/// - Clear community alert confirmation explaining that an urgent missing pin will be
///   broadcasted to the Community Animal Map and Feed.
class ReportMissingSheet extends StatefulWidget {
  final Pet pet;
  final LocationService? locationService;

  const ReportMissingSheet({
    super.key,
    required this.pet,
    this.locationService,
  });

  /// Helper static method to present the modal bottom sheet.
  static Future<ReportMissingResult?> show({
    required BuildContext context,
    required Pet pet,
    LocationService? locationService,
  }) {
    return showModalBottomSheet<ReportMissingResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ReportMissingSheet(
        pet: pet,
        locationService: locationService,
      ),
    );
  }

  @override
  State<ReportMissingSheet> createState() => _ReportMissingSheetState();
}

class _ReportMissingSheetState extends State<ReportMissingSheet> {
  final TextEditingController _noteController = TextEditingController();

  late final LocationService _locationService;
  double? _latitude;
  double? _longitude;
  bool _isFetchingLocation = true;
  bool _locationFailed = false;

  // Cebu default fallback coordinates if hardware GPS is unavailable
  static const double _defaultLat = LocationConstants.defaultLatitude;
  static const double _defaultLng = LocationConstants.defaultLongitude;

  @override
  void initState() {
    super.initState();
    _locationService = widget.locationService ?? const GeolocatorLocationService();
    _fetchCurrentLocation();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() {
      _isFetchingLocation = true;
      _locationFailed = false;
    });

    try {
      final position = await _locationService.getCurrentPosition().timeout(
        const Duration(seconds: 6),
        onTimeout: () => null,
      );

      if (!mounted) return;

      if (position != null) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _isFetchingLocation = false;
          _locationFailed = false;
        });
      } else {
        setState(() {
          _latitude = _defaultLat;
          _longitude = _defaultLng;
          _isFetchingLocation = false;
          _locationFailed = true;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _latitude = _defaultLat;
        _longitude = _defaultLng;
        _isFetchingLocation = false;
        _locationFailed = true;
      });
    }
  }

  void _handleSubmit() {
    final lat = _latitude ?? _defaultLat;
    final lng = _longitude ?? _defaultLng;
    final note = _noteController.text.trim();

    Navigator.of(context).pop(
      ReportMissingResult(
        latitude: lat,
        longitude: lng,
        note: note,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final pet = widget.pet;

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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DragHandle(),
            const SizedBox(height: 12),

            // Header Title with Alert Icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.contrast2.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.campaign_rounded,
                    color: AppColors.contrast2,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Report ${pet.name} Missing',
                        style: const TextStyle(
                          fontFamily: 'Nunito Sans',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkCharcoal,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Alert nearby community members & map users',
                        style: TextStyle(
                          fontFamily: 'Ek Mukta',
                          fontSize: 13,
                          color: AppColors.text3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Pet Quick Summary Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background2.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: pet.photoURLs.isNotEmpty
                        ? Image.network(
                            pet.photoURLs.first,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.pets,
                              color: AppColors.primary,
                            ),
                          )
                        : const Icon(
                            Icons.pets,
                            color: AppColors.primary,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pet.name,
                          style: const TextStyle(
                            fontFamily: 'Nunito Sans',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkCharcoal,
                          ),
                        ),
                        Text(
                          '${pet.species}${pet.breed != null && pet.breed!.isNotEmpty ? ' • ${pet.breed}' : ''}',
                          style: const TextStyle(
                            fontFamily: 'Ek Mukta',
                            fontSize: 13,
                            color: AppColors.text3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.contrast2,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'MISSING',
                      style: TextStyle(
                        fontFamily: 'Nunito Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Location Box Section
            const Text(
              'Last Known Location (GPS / Animal Map)',
              style: TextStyle(
                fontFamily: 'Nunito Sans',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.darkCharcoal,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _locationFailed ? AppColors.accentOrange : Colors.grey.shade300,
                ),
              ),
              child: _isFetchingLocation
                  ? const Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Acquiring current GPS location...',
                          style: TextStyle(
                            fontFamily: 'Ek Mukta',
                            fontSize: 13,
                            color: AppColors.text3,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Icon(
                          _locationFailed ? Icons.location_off_outlined : Icons.my_location,
                          size: 20,
                          color: _locationFailed ? AppColors.accentOrange : AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_latitude!.toStringAsFixed(4)}° N, ${_longitude!.toStringAsFixed(4)}° E',
                                style: const TextStyle(
                                  fontFamily: 'Nunito Sans',
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.darkCharcoal,
                                ),
                              ),
                              Text(
                                _locationFailed
                                    ? LocationConstants.defaultFallbackNote
                                    : 'Device GPS Location',
                                style: TextStyle(
                                  fontFamily: 'Ek Mukta',
                                  fontSize: 11.5,
                                  color: _locationFailed ? AppColors.accentOrange : AppColors.text3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.pin_drop_outlined, size: 20, color: AppColors.primary),
                          tooltip: 'Pin on Animal Map',
                          onPressed: () async {
                            final picked = await LocationPinPickerSheet.show(
                              context: context,
                              initialLocation: LatLng(_latitude ?? _defaultLat, _longitude ?? _defaultLng),
                              pinStatus: 'missing',
                              title: 'Pin ${widget.pet.name} on Animal Map',
                              locationService: _locationService,
                            );
                            if (picked != null) {
                              setState(() {
                                _latitude = picked.latitude;
                                _longitude = picked.longitude;
                                _locationFailed = false;
                              });
                            }
                          },
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 18, color: AppColors.primary),
                          tooltip: 'Refresh Location',
                          onPressed: _fetchCurrentLocation,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 18),

            // Last Seen Details / Note
            const Text(
              'Last Seen Details (Optional)',
              style: TextStyle(
                fontFamily: 'Nunito Sans',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.darkCharcoal,
              ),
            ),
            const SizedBox(height: 6),
            PawTextField(
              controller: _noteController,
              hintText: 'e.g., Slipped leash near the park entrance around 4:30 PM. Wearing a blue collar.',
              maxLines: 3,
            ),
            const SizedBox(height: 18),

            // Warning Notice Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.contrast1.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.contrast1.withValues(alpha: 0.3)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: AppColors.contrast1,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Submitting will mark this pet as missing and place an active alert pin on the Community Animal Map for nearby neighbors.',
                      style: TextStyle(
                        fontFamily: 'Ek Mukta',
                        fontSize: 12,
                        color: AppColors.darkCharcoal,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
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
                    text: 'Broadcast Alert',
                    icon: Icons.campaign_rounded,
                    color: AppColors.contrast2,
                    textColor: Colors.white,
                    isLoading: _isFetchingLocation,
                    onPressed: _handleSubmit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
