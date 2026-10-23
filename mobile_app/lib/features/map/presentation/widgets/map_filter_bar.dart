import 'package:flutter/material.dart';
import 'package:paws_and_found/core/theme/wireframe_colors.dart';

/// A filter bar molecule for toggling map discovery modes.
///
/// Contains:
/// - "All" pill button
/// - "For You" pill button
/// - "Animal Type ▼" species filter pill
///
/// Adheres to Atomic Design: dumb, stateless UI element relying purely on
/// passed properties and callbacks.
class MapFilterBar extends StatelessWidget {
  final String selectedFilter; // 'all' or 'for_you'
  final String? selectedAnimalType;
  final ValueChanged<String> onFilterSelected;
  final VoidCallback onAnimalTypePressed;

  const MapFilterBar({
    super.key,
    required this.selectedFilter,
    this.selectedAnimalType,
    required this.onFilterSelected,
    required this.onAnimalTypePressed,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAllSelected = selectedFilter.toLowerCase() == 'all';
    final bool isForYouSelected = selectedFilter.toLowerCase() == 'for_you' ||
        selectedFilter.toLowerCase() == 'foryou';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          // "All" filter pill
          _buildFilterPill(
            label: 'All',
            isSelected: isAllSelected,
            onTap: () => onFilterSelected('all'),
          ),
          const SizedBox(width: 8),

          // "For You" filter pill
          _buildFilterPill(
            label: 'For You',
            isSelected: isForYouSelected,
            onTap: () => onFilterSelected('for_you'),
          ),
          const SizedBox(width: 8),

          // "Animal Type" dropdown filter pill
          _buildFilterPill(
            label: selectedAnimalType != null
                ? 'Type: $selectedAnimalType'
                : 'Animal Type',
            isSelected: selectedAnimalType != null,
            trailingIcon: const Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: WireframeColors.textSecondary,
            ),
            onTap: onAnimalTypePressed,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Widget? trailingIcon,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? WireframeColors.primaryDark
              : WireframeColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? WireframeColors.primaryDark
                : WireframeColors.border,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : WireframeColors.textPrimary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 2),
              trailingIcon,
            ],
          ],
        ),
      ),
    );
  }
}
