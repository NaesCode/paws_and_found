import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';
import 'package:paws_and_found/features/auth/domain/repositories/auth_repository.dart';
import 'package:paws_and_found/features/auth/presentation/widgets/auth_map_background.dart';
import 'package:paws_and_found/features/auth/presentation/widgets/auth_tray.dart';
import 'package:paws_and_found/shared/molecules/app_brand_title_placeholder.dart';

/// The authentication screen for Paws and Found.
///
/// Features a stylized digital map background with sequential animated paw-step
/// tracks, a hero brand emblem & title that centers symmetrically when the tray
/// is dragged down, and the draggable [AuthTray] organism at the bottom.
class LoginPage extends StatefulWidget {
  final AuthRepository? authRepository;

  const LoginPage({super.key, this.authRepository});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  bool isLogin = true;

  /// 0.0 = AuthTray is up (open), 1.0 = AuthTray is dragged down (collapsed).
  AnimationController? _trayController;

  /// Controls the sequential reveal of paw steps on the digital map.
  AnimationController? _pawController;

  static const double _collapsedPeekHeight = 72.0;

  @override
  void initState() {
    super.initState();
    _ensureControllers();
  }

  /// Lazily initializes controllers so hot reload on an already-mounted State
  /// never triggers a LateInitializationError.
  void _ensureControllers() {
    _trayController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      value: 0.0,
    );
    if (_pawController == null) {
      _pawController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2200),
      );
      _pawController!.forward();
    }
  }

  @override
  void dispose() {
    _trayController?.dispose();
    _pawController?.dispose();
    super.dispose();
  }

  void _collapseTray() {
    FocusScope.of(context).unfocus();
    _trayController?.animateTo(1.0, curve: Curves.easeOutCubic);
    _pawController?.forward(from: 0.0);
  }

  void _expandTray() {
    _trayController?.animateTo(0.0, curve: Curves.easeOutCubic);
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details, double maxDrag) {
    final tray = _trayController;
    if (tray == null || maxDrag <= 0) return;
    final delta = details.delta.dy / maxDrag;
    tray.value = (tray.value + delta).clamp(0.0, 1.0);
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    final tray = _trayController;
    if (tray == null) return;
    final velocity = details.primaryVelocity ?? 0.0;
    if (velocity > 350) {
      _collapseTray();
    } else if (velocity < -350) {
      _expandTray();
    } else if (tray.value > 0.38) {
      _collapseTray();
    } else {
      _expandTray();
    }
  }

  @override
  Widget build(BuildContext context) {
    _ensureControllers();
    final trayController = _trayController!;
    final pawController = _pawController!;

    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final maxDragDistance = (screenHeight * 0.62 - _collapsedPeekHeight).clamp(180.0, 560.0);

    return Scaffold(
      backgroundColor: AppColors.surfaceMuted,
      body: Stack(
        children: [
          // 1. Stylized Digital Map + Sequential Paw-Step Trail Background
          Positioned.fill(
            child: AuthMapBackground(pawProgress: pawController),
          ),

          // 2. Brand Emblem & Title Hero Area
          // Symmetrically centers on screen when the AuthTray is dragged down.
          SafeArea(
            child: AnimatedBuilder(
              animation: trayController,
              builder: (context, child) {
                final t = Curves.easeInOut.transform(trayController.value);
                final alignment = Alignment.lerp(
                  const Alignment(0.0, -0.82),
                  Alignment.center,
                  t,
                )!;
                final scale = lerpDouble(1.0, 1.12, t)!;

                return Align(
                  alignment: alignment,
                  child: Transform.scale(
                    scale: scale,
                    child: child,
                  ),
                );
              },
              child: const AppBrandTitlePlaceholder(
                logoSize: 76.0,
                showBadge: false,
                useSvgLogo: true,
                title: 'Paws and Found',
                subtitle: 'Community Lost & Found Animal Recovery',
              ),
            ),
          ),

          // 4. Draggable Authentication Tray (Organism)
          AnimatedBuilder(
            animation: trayController,
            builder: (context, child) {
              final offsetY = maxDragDistance * trayController.value;
              final isCollapsed = trayController.value > 0.65;

              return Align(
                alignment: Alignment.bottomCenter,
                child: Transform.translate(
                  offset: Offset(0, offsetY),
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onVerticalDragUpdate: (d) =>
                        _handleVerticalDragUpdate(d, maxDragDistance),
                    onVerticalDragEnd: _handleVerticalDragEnd,
                    child: Stack(
                      children: [
                        child!,
                        // Subtle pull-up indicator overlay when collapsed
                        if (isCollapsed)
                          Positioned(
                            top: 26,
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: GestureDetector(
                              onTap: _expandTray,
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                color: Colors.white,
                                padding: const EdgeInsets.only(top: 10),
                                alignment: Alignment.topCenter,
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.keyboard_arrow_up_rounded,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Swipe up or tap to sign in',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
            child: AuthTray(
              isLogin: isLogin,
              onModeChanged: (value) => setState(() => isLogin = value),
              repository: widget.authRepository,
            ),
          ),
        ],
      ),
    );
  }
}
