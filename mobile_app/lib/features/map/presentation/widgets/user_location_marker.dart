import 'package:flutter/material.dart';

/// An atom representing the user's current GPS location on the map.
///
/// Displays a high-visibility location indicator with a blue central core,
/// crisp white inner border, and a translucent outer accuracy halo.
///
/// Adheres to Atomic Design: dumb, stateless UI element.
class UserLocationMarker extends StatelessWidget {
  final double size;
  final Color coreColor;
  final Color haloColor;

  const UserLocationMarker({
    super.key,
    this.size = 28.0,
    this.coreColor = const Color(0xFF2563EB), // Vibrant blue
    this.haloColor = const Color(0x332563EB), // 20% opacity halo
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: haloColor,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Container(
          width: size * 0.55,
          height: size * 0.55,
          decoration: BoxDecoration(
            color: coreColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 2.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4.0,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
