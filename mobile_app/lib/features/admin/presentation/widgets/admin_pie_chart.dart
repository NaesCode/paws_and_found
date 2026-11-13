import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/wireframe_colors.dart';

/// Represents a single slice / category in the Admin Pie/Donut Chart.
class PieChartSegment {
  final String label;
  final double value;
  final Color color;
  final IconData? icon;

  const PieChartSegment({
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  });
}

/// Custom Donut / Pie Chart widget for visualizing post status distributions
/// in the Admin Analytics view.
class AdminPieChart extends StatelessWidget {
  final List<PieChartSegment> segments;
  final double size;
  final double strokeWidth;
  final String centerLabel;
  final String centerSublabel;
  final bool showLegend;

  const AdminPieChart({
    super.key,
    required this.segments,
    this.size = 180,
    this.strokeWidth = 26,
    this.centerLabel = '',
    this.centerSublabel = 'TOTAL',
    this.showLegend = true,
  });

  double get totalValue =>
      segments.fold(0.0, (sum, seg) => sum + math.max(0.0, seg.value));

  @override
  Widget build(BuildContext context) {
    final total = totalValue;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Donut Chart Graphic with Center Metric
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _DonutChartPainter(
                  segments: segments,
                  strokeWidth: strokeWidth,
                  total: total,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    centerLabel.isNotEmpty ? centerLabel : total.toInt().toString(),
                    style: const TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.w800,
                      color: WireframeColors.primaryDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    centerSublabel.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10.0,
                      fontWeight: FontWeight.w700,
                      color: WireframeColors.textMuted,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Structured Legend
        if (showLegend && segments.isNotEmpty) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: WireframeColors.border),
            ),
            child: Column(
              children: segments.map((seg) {
                final percentage =
                    total > 0 ? (seg.value / total * 100).toStringAsFixed(1) : '0.0';
                final isLast = seg == segments.last;

                return Column(
                  children: [
                    Row(
                      children: [
                        // Color Pill
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: seg.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Label
                        Expanded(
                          child: Text(
                            seg.label,
                            style: const TextStyle(
                              fontSize: 13.0,
                              fontWeight: FontWeight.w600,
                              color: WireframeColors.textPrimary,
                            ),
                          ),
                        ),
                        // Count
                        Text(
                          '${seg.value.toInt()} posts',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: WireframeColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Percentage badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6.0, vertical: 2.0),
                          decoration: BoxDecoration(
                            color: seg.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: Text(
                            '$percentage%',
                            style: TextStyle(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w700,
                              color: seg.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!isLast) const Divider(height: 14, color: WireframeColors.border),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<PieChartSegment> segments;
  final double strokeWidth;
  final double total;

  _DonutChartPainter({
    required this.segments,
    required this.strokeWidth,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Empty state ring
    if (total <= 0) {
      final emptyPaint = Paint()
        ..color = WireframeColors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawCircle(center, radius, emptyPaint);
      return;
    }

    // Gap between segments in radians (if multiple non-zero segments)
    final activeCount = segments.where((s) => s.value > 0).length;
    final gapAngle = activeCount > 1 ? (3.0 * math.pi / 180.0) : 0.0;

    double currentAngle = -math.pi / 2; // Start from top (12 o'clock)

    for (final seg in segments) {
      if (seg.value <= 0) continue;
      final sweepAngle = (seg.value / total) * 2 * math.pi;
      final drawSweep = math.max(0.01, sweepAngle - gapAngle);

      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, currentAngle + (gapAngle / 2), drawSweep, false, paint);
      currentAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.total != total ||
        oldDelegate.segments != segments ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
