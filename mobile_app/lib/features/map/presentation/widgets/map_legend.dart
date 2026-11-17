import 'package:flutter/material.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';
import '../../../../shared/atoms/map_pin_badge.dart';

/// A map legend molecule showing pin status definitions.
///
/// Displays:
/// - (M) Missing
/// - (S) Stray
/// - (F) Found
///
/// Adheres to Atomic Design: dumb, stateless UI element relying purely on
/// passed properties.
class MapLegend extends StatelessWidget {
  final String? selectedStatus;
  final ValueChanged<String>? onStatusSelected;

  const MapLegend({
    super.key,
    this.selectedStatus,
    this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem(label: 'M', status: 'missing', title: 'Missing'),
          const SizedBox(width: 14),
          _buildLegendItem(label: 'S', status: 'stray', title: 'Stray'),
          const SizedBox(width: 14),
          _buildLegendItem(label: 'F', status: 'found', title: 'Found'),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required String label,
    required String status,
    required String title,
  }) {
    final bool isSelected = selectedStatus?.toLowerCase() == status.toLowerCase();

    return GestureDetector(
      onTap: () => onStatusSelected?.call(status),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 1.2)
              : Border.all(color: Colors.transparent, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MapPinBadge(
              label: label,
              status: status,
              size: 22,
              isSelected: isSelected,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? AppColors.darkCharcoal
                    : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
