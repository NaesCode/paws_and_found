import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Decorative background paws scattered in the right portion of the identity block.
/// Purely decorative, excluded from semantics and wrapped in IgnorePointer.
class PawPrintDecoration extends StatelessWidget {
  const PawPrintDecoration({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: const [
          Positioned(
            top: 10,
            right: 80,
            child: _DecorativePaw(size: 16, angle: 15, opacity: 0.35),
          ),
          Positioned(
            top: 25,
            right: 125,
            child: _DecorativePaw(size: 14, angle: -20, opacity: 0.30),
          ),
          Positioned(
            top: 45,
            right: 95,
            child: _DecorativePaw(size: 18, angle: 25, opacity: 0.40),
          ),
          Positioned(
            top: 20,
            right: 45,
            child: _DecorativePaw(size: 15, angle: -15, opacity: 0.30),
          ),
          Positioned(
            top: 55,
            right: 55,
            child: _DecorativePaw(size: 16, angle: 10, opacity: 0.35),
          ),
          Positioned(
            top: 35,
            right: 15,
            child: _DecorativePaw(size: 17, angle: -25, opacity: 0.30),
          ),
          Positioned(
            top: 65,
            right: 25,
            child: _DecorativePaw(size: 13, angle: 18, opacity: 0.28),
          ),
          Positioned(
            top: 58,
            right: 110,
            child: _DecorativePaw(size: 15, angle: -10, opacity: 0.35),
          ),
        ],
      ),
    );
  }
}

class _DecorativePaw extends StatelessWidget {
  final double size;
  final double angle; // in degrees
  final double opacity;

  const _DecorativePaw({
    required this.size,
    required this.angle,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle * (math.pi / 180),
      child: Icon(
        Icons.pets,
        size: size,
        color: AppColors.background2.withValues(alpha: opacity),
      ),
    );
  }
}

