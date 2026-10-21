import 'package:flutter/material.dart';
import 'package:paws_and_found/core/theme/wireframe_colors.dart';

/// A template defining the structural layout for the Community Animal Map screen.
///
/// Slots:
/// - [header]: Top bar containing the screen title and actions.
/// - [filterBar]: Horizontal filter pills row.
/// - [mapCanvas]: Interactive geographic map area (or placeholder).
/// - [reportCard]: Floating report detail card (nullable).
/// - [legend]: Pin status legend at the bottom (nullable).
/// - [bottomNavigationBar]: Bottom navigation bar or placeholder (nullable).
///
/// Adheres to Atomic Design: dumb, stateless layout template.
class MapScreenTemplate extends StatelessWidget {
  final Widget header;
  final Widget filterBar;
  final Widget mapCanvas;
  final Widget? reportCard;
  final Widget? legend;
  final Widget? bottomNavigationBar;

  const MapScreenTemplate({
    super.key,
    required this.header,
    required this.filterBar,
    required this.mapCanvas,
    this.reportCard,
    this.legend,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WireframeColors.background,
      body: SafeArea(
        bottom: bottomNavigationBar == null,
        child: Column(
          children: [
            // 1. Header
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
              child: header,
            ),

            // 2. Filter Sub-menu Container
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: filterBar,
            ),

            // 3. Main Map Canvas + Floating Overlay Area
            Expanded(
              child: Stack(
                children: [
                  // Base Map Canvas (fills available area)
                  Positioned.fill(child: mapCanvas),

                  // Floating elements at the bottom of the map canvas
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (reportCard != null) ...[
                          reportCard!,
                          const SizedBox(height: 10),
                        ],
                        if (legend != null) ...[
                          legend!,
                          const SizedBox(height: 6),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
