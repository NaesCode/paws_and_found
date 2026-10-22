import 'package:flutter/material.dart';
import 'package:paws_and_found/core/theme/wireframe_colors.dart';
import './map_pin_badge.dart';

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
  const MapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem(label: 'M', status: 'missing', title: 'Missing'),
          const SizedBox(width: 20),
          _buildLegendItem(label: 'S', status: 'stray', title: 'Stray'),
          const SizedBox(width: 20),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MapPinBadge(
          label: label,
          status: status,
          size: 22,
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            color: WireframeColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
