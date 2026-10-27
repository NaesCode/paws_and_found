import 'package:flutter/material.dart';
import 'package:paws_and_found/core/theme/wireframe_colors.dart';

/// Form organism for Animal Report Creation (SDD Screen 05).
///
/// Fields:
/// - Animal Type selector ("Canine", "Feline", "Other")
/// - Status selector ("Stray", "Missing", "Found")
/// - Description text area
/// - Date / Time readout
/// - GPS / Map Pin coordinate field with interactive Animal Map Pinning
/// - "Submit Report" primary button
///
/// Adheres to Atomic Design: dumb, stateless UI element relying purely on
/// passed properties and callbacks.
class CreateReportForm extends StatelessWidget {
  final String animalType;
  final String status;
  final TextEditingController descriptionController;
  final String dateTimeString;
  final bool isGpsAuto;
  final bool isLoading;
  final double? pinnedLat;
  final double? pinnedLng;
  final double? deviceLat;
  final double? deviceLng;
  final ValueChanged<String> onAnimalTypeChanged;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onToggleGps;
  final VoidCallback? onPinOnMap;
  final VoidCallback onSubmit;

  const CreateReportForm({
    super.key,
    required this.animalType,
    required this.status,
    required this.descriptionController,
    required this.dateTimeString,
    this.isGpsAuto = true,
    this.isLoading = false,
    this.pinnedLat,
    this.pinnedLng,
    this.deviceLat,
    this.deviceLng,
    required this.onAnimalTypeChanged,
    required this.onStatusChanged,
    required this.onToggleGps,
    this.onPinOnMap,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isMissing = status.toLowerCase() == 'missing';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title: "CREATE REPORT"
          const Text(
            'CREATE REPORT',
            style: TextStyle(
              color: WireframeColors.textSecondary,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 16),

          // Row 1: Animal Type & Status
          Row(
            children: [
              Expanded(
                child: _buildDropdownField(
                  label: 'ANIMAL TYPE',
                  value: animalType,
                  items: const ['Canine', 'Feline', 'Other'],
                  onChanged: onAnimalTypeChanged,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildDropdownField(
                  label: 'STATUS',
                  value: status,
                  items: const ['Stray', 'Missing', 'Found'],
                  onChanged: onStatusChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Row 2: Description Block
          _buildFieldLabel('DESCRIPTION'),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: WireframeColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: WireframeColors.border, width: 1.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: TextField(
              controller: descriptionController,
              maxLines: 3,
              style: const TextStyle(
                color: WireframeColors.textPrimary,
                fontSize: 13.5,
              ),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: 'Enter appearance, collar, markings, or behavior details...',
                hintStyle: TextStyle(
                  color: WireframeColors.textMuted,
                  fontSize: 12.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Row 3: Date/Time & GPS / MAP PIN
          Row(
            children: [
              // Date / Time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('DATE / TIME'),
                    const SizedBox(height: 6),
                    Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: WireframeColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: WireframeColors.border, width: 1.0),
                      ),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        dateTimeString,
                        style: const TextStyle(
                          color: WireframeColors.textSecondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Unified GPS / Map Pin Field
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('GPS / MAP PIN'),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () {
                        if (onPinOnMap != null) {
                          onPinOnMap!();
                        } else {
                          onToggleGps();
                        }
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: WireframeColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: pinnedLat != null
                                ? WireframeColors.primaryDark
                                : WireframeColors.border,
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isGpsAuto
                                      ? WireframeColors.primaryDark
                                      : WireframeColors.border,
                                  width: 2.0,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: isGpsAuto
                                  ? Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: WireframeColors.primaryDark,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                pinnedLat != null
                                    ? '${pinnedLat!.toStringAsFixed(2)}°, ${pinnedLng!.toStringAsFixed(2)}°'
                                    : (deviceLat != null && isGpsAuto
                                        ? 'GPS (${deviceLat!.toStringAsFixed(2)}°, ${deviceLng!.toStringAsFixed(2)}°)'
                                        : (isGpsAuto ? 'Auto' : 'Pin on Map')),
                                style: TextStyle(
                                  color: (pinnedLat != null || (deviceLat != null && isGpsAuto))
                                      ? WireframeColors.primaryDark
                                      : WireframeColors.textPrimary,
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (onPinOnMap != null)
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: Icon(
                                  Icons.pin_drop_rounded,
                                  size: 19,
                                  color: pinnedLat != null
                                      ? WireframeColors.primaryDark
                                      : WireframeColors.secondarySlate,
                                ),
                                tooltip: 'Pin on Animal Map',
                                onPressed: onPinOnMap,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Row 4: "Submit Report" Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: isLoading ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: WireframeColors.primaryDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isMissing ? 'Submit Missing Animal Report' : 'Submit Report',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: WireframeColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label),
        const SizedBox(height: 6),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: WireframeColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: WireframeColors.border, width: 1.0),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: WireframeColors.secondarySlate),
              style: const TextStyle(
                color: WireframeColors.textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) onChanged(val);
              },
            ),
          ),
        ),
      ],
    );
  }
}
