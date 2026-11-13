import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/wireframe_colors.dart';

/// Single bar item representing a period (day or week) in user growth.
class BarChartGroup {
  final String label;
  final int value;
  final bool isHighlight;

  const BarChartGroup({
    required this.label,
    required this.value,
    this.isHighlight = false,
  });
}

/// Custom Bar Chart widget for visualizing new user registrations over time
/// (weekly or monthly) in Admin Analytics.
class AdminBarChart extends StatelessWidget {
  final List<BarChartGroup> groups;
  final double height;
  final String unitLabel;

  const AdminBarChart({
    super.key,
    required this.groups,
    this.height = 150,
    this.unitLabel = 'new users',
  });

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return Container(
        height: height,
        alignment: Alignment.center,
        child: const Text(
          'No registration activity recorded',
          style: TextStyle(fontSize: 12.0, color: WireframeColors.textMuted),
        ),
      );
    }

    final maxValue = groups.fold<int>(0, (max, g) => math.max(max, g.value));
    final effectiveMax = maxValue == 0 ? 1 : maxValue;

    return Column(
      children: [
        SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: groups.map((g) {
              final ratio = (g.value / effectiveMax).clamp(0.0, 1.0);
              // Minimum bar height so empty bars still display an indicator
              final barHeight = math.max(6.0, ratio * (height - 32));

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Value indicator label
                      Text(
                        g.value.toString(),
                        style: TextStyle(
                          fontSize: 11.0,
                          fontWeight: g.isHighlight ? FontWeight.w800 : FontWeight.w600,
                          color: g.isHighlight
                              ? WireframeColors.primaryDark
                              : (g.value > 0
                                  ? WireframeColors.textPrimary
                                  : WireframeColors.textMuted),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Bar
                      Container(
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: g.isHighlight
                              ? WireframeColors.primaryDark
                              : (g.value > 0
                                  ? WireframeColors.primaryDark.withValues(alpha: 0.65)
                                  : WireframeColors.border),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(5.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Bottom Axis Line
        Container(
          height: 1.5,
          color: WireframeColors.border,
        ),
        const SizedBox(height: 6),

        // X-Axis Labels
        Row(
          children: groups.map((g) {
            return Expanded(
              child: Center(
                child: Text(
                  g.label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: g.isHighlight ? FontWeight.w700 : FontWeight.w500,
                    color: g.isHighlight
                        ? WireframeColors.primaryDark
                        : WireframeColors.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
