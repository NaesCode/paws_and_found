import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';

class MeetupLocationResult {
  final String placeName;
  final double lat;
  final double lng;

  MeetupLocationResult({
    required this.placeName,
    required this.lat,
    required this.lng,
  });
}

Future<MeetupLocationResult?> showMeetupMapPicker(
  BuildContext context, {
  LatLng initialCenter = const LatLng(10.3157, 123.8854), // Cebu City default
  String? initialAddress,
}) {
  return showModalBottomSheet<MeetupLocationResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _MeetupMapPickerSheet(
      initialCenter: initialCenter,
      initialAddress: initialAddress,
    ),
  );
}

class _MeetupMapPickerSheet extends StatefulWidget {
  final LatLng initialCenter;
  final String? initialAddress;

  const _MeetupMapPickerSheet({
    required this.initialCenter,
    this.initialAddress,
  });

  @override
  State<_MeetupMapPickerSheet> createState() => _MeetupMapPickerSheetState();
}

class _MeetupMapPickerSheetState extends State<_MeetupMapPickerSheet> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  late LatLng _pinnedLocation;
  String _resolvedAddress = '';
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  bool _isReverseGeocoding = false;

  @override
  void initState() {
    super.initState();
    _pinnedLocation = widget.initialCenter;
    _resolvedAddress = widget.initialAddress ?? 'Pinned Meetup Spot';
    if (widget.initialAddress == null || widget.initialAddress!.isEmpty) {
      _reverseGeocode(_pinnedLocation);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchPlaces(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 3) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(trimmed)}&format=json&limit=5&countrycodes=ph',
      );
      final res = await http.get(
        uri,
        headers: {'User-Agent': 'paws_and_found_app'},
      );
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body) as List<dynamic>;
        setState(() {
          _searchResults = data;
        });
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _reverseGeocode(LatLng point) async {
    setState(() => _isReverseGeocoding = true);
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=${point.latitude}&lon=${point.longitude}&format=json',
      );
      final res = await http.get(
        uri,
        headers: {'User-Agent': 'paws_and_found_app'},
      );
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final display = data['display_name']?.toString() ?? '';
        if (display.isNotEmpty) {
          final parts = display
              .split(',')
              .map((e) => e.trim())
              .take(3)
              .join(', ');
          setState(() => _resolvedAddress = parts);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _resolvedAddress =
              'Pinned Spot (${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)})';
        });
      }
    } finally {
      if (mounted) setState(() => _isReverseGeocoding = false);
    }
  }

  void _onPinMoved(LatLng newPoint) {
    setState(() {
      _pinnedLocation = newPoint;
      _searchResults = [];
    });
    _reverseGeocode(newPoint);
  }

  @override
  Widget build(BuildContext context) {
    final sheetHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      height: sheetHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Pin Safe Meetup Location',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkCharcoal,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _searchController,
              onChanged: _searchPlaces,
              decoration: InputDecoration(
                hintText: 'Search mall, barangay hall, police station...',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: AppColors.text3,
                ),
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : (_searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchResults = []);
                              },
                            )
                          : null),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Interactive Map + Search Dropdown Overlay
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _pinnedLocation,
                    initialZoom: 15.5,
                    onTap: (_, latLng) => _onPinMoved(latLng),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.paws_and_found',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _pinnedLocation,
                          width: 48,
                          height: 48,
                          child: const Icon(
                            Icons.location_pin,
                            size: 44,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Hint pill
                Positioned(
                  top: 12,
                  left: 16,
                  right: 16,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Tap anywhere on the map to drop the meetup pin',
                        style: TextStyle(color: Colors.white, fontSize: 11.5),
                      ),
                    ),
                  ),
                ),

                // Search Results List
                if (_searchResults.isNotEmpty)
                  Positioned(
                    top: 4,
                    left: 16,
                    right: 16,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, idx) {
                          final item = _searchResults[idx];
                          final name = item['display_name']?.toString() ?? '';
                          return ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.place_outlined,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            title: Text(
                              name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12.5),
                            ),
                            onTap: () {
                              final lat = double.parse(item['lat'].toString());
                              final lng = double.parse(item['lon'].toString());
                              final point = LatLng(lat, lng);
                              final shortName = name
                                  .split(',')
                                  .map((e) => e.trim())
                                  .take(3)
                                  .join(', ');
                              setState(() {
                                _pinnedLocation = point;
                                _resolvedAddress = shortName;
                                _searchResults = [];
                                _searchController.text = shortName;
                              });
                              _mapController.move(point, 16.5);
                            },
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Selected Pin Summary & Confirm Pin Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'SELECTED MEETUP SPOT:',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isReverseGeocoding
                        ? 'Resolving address...'
                        : _resolvedAddress,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkCharcoal,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(
                        Icons.push_pin_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: const Text(
                        'Use This Pinned Location',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(
                          context,
                          MeetupLocationResult(
                            placeName: _resolvedAddress,
                            lat: _pinnedLocation.latitude,
                            lng: _pinnedLocation.longitude,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
