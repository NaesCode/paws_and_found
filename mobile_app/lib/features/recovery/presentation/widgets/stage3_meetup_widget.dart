import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';
import 'popups/safe_meetup_picker_sheet.dart';

class Stage3MeetupWidget extends StatefulWidget {
  final bool isFinderView;
  final bool isReadOnly;
  final String petName;
  final String otherPartyName;
  final String? selectedPlace;
  final double? selectedLat;
  final double? selectedLng;
  final String? selectedTime;
  final bool myMeetupAgreed;
  final bool isMeetupConfirmed;
  final bool myHandoverConfirmed;
  final bool otherHandoverConfirmed;
  final Future<void> Function(String place, double lat, double lng, String time) onProposeMeetup;
  final Future<void> Function() onConfirmMeetup;
  final VoidCallback onConfirmHandoverTap;

  const Stage3MeetupWidget({
    super.key,
    required this.isFinderView,
    this.isReadOnly = false,
    required this.petName,
    required this.otherPartyName,
    required this.selectedPlace,
    this.selectedLat,
    this.selectedLng,
    required this.selectedTime,
    required this.myMeetupAgreed,
    required this.isMeetupConfirmed,
    required this.myHandoverConfirmed,
    required this.otherHandoverConfirmed,
    required this.onProposeMeetup,
    required this.onConfirmMeetup,
    required this.onConfirmHandoverTap,
  });

  @override
  State<Stage3MeetupWidget> createState() => _Stage3MeetupWidgetState();
}

class _Stage3MeetupWidgetState extends State<Stage3MeetupWidget> {
  String? _draftPlace;
  double? _draftLat;
  double? _draftLng;
  String _draftTime = 'Today, 4:00 PM';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _draftPlace = widget.selectedPlace;
    _draftLat = widget.selectedLat;
    _draftLng = widget.selectedLng;
    if (widget.selectedTime != null && widget.selectedTime!.isNotEmpty) {
      _draftTime = widget.selectedTime!;
    }
  }

  @override
  void didUpdateWidget(covariant Stage3MeetupWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedPlace != oldWidget.selectedPlace ||
        widget.selectedLat != oldWidget.selectedLat ||
        widget.selectedLng != oldWidget.selectedLng) {
      _draftPlace = widget.selectedPlace;
      _draftLat = widget.selectedLat;
      _draftLng = widget.selectedLng;
    }
    if (widget.selectedTime != null && widget.selectedTime != oldWidget.selectedTime) {
      _draftTime = widget.selectedTime!;
    }
  }

  Future<void> _openMapPicker() async {
    final initial = (_draftLat != null && _draftLng != null)
        ? LatLng(_draftLat!, _draftLng!)
        : const LatLng(10.3157, 123.8854); // Cebu City default

    final picked = await showMeetupMapPicker(
      context,
      initialCenter: initial,
      initialAddress: _draftPlace,
    );

    if (picked != null && mounted) {
      setState(() {
        _draftPlace = picked.placeName;
        _draftLat = picked.lat;
        _draftLng = picked.lng;
      });
    }
  }

  Future<void> _pickMeetupDateAndTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime == null || !mounted) return;

    final formattedDate = MaterialLocalizations.of(context).formatMediumDate(pickedDate);
    final formattedTime = pickedTime.format(context);

    setState(() {
      _draftTime = '$formattedDate • $formattedTime';
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasProposedSpot = widget.selectedPlace != null &&
        widget.selectedPlace!.isNotEmpty &&
        widget.selectedLat != null &&
        widget.selectedLng != null;

    final displayPlace = _draftPlace ?? widget.selectedPlace;
    final displayLat = _draftLat ?? widget.selectedLat;
    final displayLng = _draftLng ?? widget.selectedLng;

    final hasUnsavedChanges = displayPlace != null &&
        (displayPlace != widget.selectedPlace ||
            displayLat != widget.selectedLat ||
            displayLng != widget.selectedLng ||
            _draftTime != (widget.selectedTime ?? 'Today, 4:00 PM'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Pinned Safe Meetup Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Safe Meetup Location',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.darkCharcoal),
                    ),
                  ),
                  if (hasProposedSpot)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: widget.isMeetupConfirmed ? AppColors.primary : AppColors.accentOrange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.isMeetupConfirmed ? 'AGREED' : 'PROPOSED',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                widget.isReadOnly
                    ? 'Completed meetup spot and schedule for this reunion.'
                    : 'Pin or search an open, public landmark (mall lobby, barangay hall, police outpost) and agree together.',
                style: const TextStyle(fontSize: 12, color: AppColors.text3),
              ),
              const SizedBox(height: 14),

              if (displayPlace != null && displayLat != null && displayLng != null) ...[
                // Pinned Mini-Map Preview
                GestureDetector(
                  onTap: widget.isReadOnly ? null : _openMapPicker,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 165,
                      width: double.infinity,
                      child: Stack(
                        children: [
                          FlutterMap(
                            key: ValueKey('$displayLat,$displayLng'),
                            options: MapOptions(
                              initialCenter: LatLng(displayLat, displayLng),
                              initialZoom: 16.0,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.none,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.paws_and_found',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(displayLat, displayLng),
                                    width: 44,
                                    height: 44,
                                    child: const Icon(
                                      Icons.location_pin,
                                      size: 40,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (!widget.isReadOnly)
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.edit_location_alt_outlined, size: 14, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text(
                                      'Change Pin',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Pinned Address & Scheduled Time Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.place_rounded, size: 17, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              displayPlace,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: AppColors.darkCharcoal,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: widget.isReadOnly ? null : _pickMeetupDateAndTime,
                        child: Row(
                          children: [
                            const Icon(Icons.event_available_rounded, size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Schedule: $_draftTime',
                                style: const TextStyle(fontSize: 12.5, color: AppColors.text2),
                              ),
                            ),
                            if (!widget.isReadOnly)
                              const Text(
                                'Change Date & Time',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                if (!widget.isReadOnly) ...[
                  const SizedBox(height: 12),

                  // Propose / Agree Actions
                  if (!hasProposedSpot || hasUnsavedChanges)
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isSaving
                            ? null
                            : () async {
                                setState(() => _isSaving = true);
                                try {
                                  await widget.onProposeMeetup(
                                    displayPlace,
                                    displayLat,
                                    displayLng,
                                    _draftTime,
                                  );
                                } finally {
                                  if (mounted) setState(() => _isSaving = false);
                                }
                              },
                        child: Text(
                          _isSaving
                              ? 'Sending...'
                              : (hasProposedSpot ? 'Propose Updated Pin' : 'Propose Meetup Spot'),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  else if (!widget.myMeetupAgreed)
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                        label: const Text(
                          'Agree to This Meetup Spot',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _isSaving
                            ? null
                            : () async {
                                setState(() => _isSaving = true);
                                try {
                                  await widget.onConfirmMeetup();
                                } finally {
                                  if (mounted) setState(() => _isSaving = false);
                                }
                              },
                      ),
                    )
                  else if (!widget.isMeetupConfirmed)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accentOrange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Waiting for ${widget.otherPartyName} to agree to this meetup spot...',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentOrange,
                        ),
                      ),
                    ),
                ],
              ] else if (!widget.isReadOnly) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.add_location_alt_outlined, color: Colors.white, size: 18),
                    label: const Text(
                      'Open Map to Pin or Search Spot',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _openMapPicker,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Both-Side Handover Confirmation Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mutual Handover Confirmation',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.darkCharcoal),
              ),
              const SizedBox(height: 6),
              const Text(
                'Both the Finder and Pet Owner must confirm once the pet is safely returned.',
                style: TextStyle(fontSize: 12, color: AppColors.text3),
              ),
              const SizedBox(height: 12),
              _buildStatusRow(
                label: 'Your Confirmation',
                confirmed: widget.myHandoverConfirmed,
              ),
              const SizedBox(height: 6),
              _buildStatusRow(
                label: '${widget.otherPartyName}\'s Confirmation',
                confirmed: widget.otherHandoverConfirmed,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentOrange,
                    disabledBackgroundColor: AppColors.background2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: (widget.isReadOnly || !widget.isMeetupConfirmed || widget.myHandoverConfirmed)
                      ? null
                      : widget.onConfirmHandoverTap,
                  child: Text(
                    widget.isReadOnly
                        ? 'Reunion Completed ✓'
                        : (widget.myHandoverConfirmed
                            ? 'Waiting for ${widget.otherPartyName}...'
                            : (widget.isMeetupConfirmed
                                ? 'Confirm Safe Handover'
                                : 'Agree on Meetup Spot First')),
                    style: TextStyle(
                      color: (!widget.isReadOnly && widget.isMeetupConfirmed && !widget.myHandoverConfirmed)
                          ? Colors.white
                          : AppColors.text3,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow({required String label, required bool confirmed}) {
    return Row(
      children: [
        Icon(
          confirmed ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          size: 18,
          color: confirmed ? AppColors.primary : AppColors.text3,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: confirmed ? FontWeight.bold : FontWeight.normal,
            color: confirmed ? AppColors.darkCharcoal : AppColors.text2,
          ),
        ),
      ],
    );
  }
}