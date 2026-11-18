import 'package:flutter/material.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';
import 'package:paws_and_found/features/auth/domain/repositories/auth_repository.dart';
import 'package:paws_and_found/features/auth/presentation/widgets/auth_tray.dart';
import 'package:paws_and_found/shared/molecules/app_brand_title_placeholder.dart';

/// The authentication screen for Paws and Found.
///
/// Features a clinical surface background with soft veterinary branding
/// and decorative paw accents in the upper hero area, while hosting
/// the interactive [AuthTray] organism at the bottom.
class LoginPage extends StatefulWidget {
  final AuthRepository? authRepository;

  const LoginPage({super.key, this.authRepository});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isLogin = true;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;

    return Scaffold(
      backgroundColor: AppColors.surfaceMuted,
      body: Stack(
        children: [
          // 1. Clinical veterinary gradient background with soft paw decorative watermarks
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFEFF7F4), // Ultra-soft mint-teal tint
                    AppColors.surfaceMuted,
                    AppColors.surface,
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // 2. Decorative background watermarks (subtle animal rescue motif)
          Positioned(
            top: screenHeight * 0.08,
            right: -24,
            child: IgnorePointer(
              child: Icon(
                Icons.pets_rounded,
                size: 140,
                color: AppColors.primary.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            top: screenHeight * 0.22,
            left: -32,
            child: IgnorePointer(
              child: Icon(
                Icons.pets_rounded,
                size: 160,
                color: AppColors.accentOrange.withValues(alpha: 0.035),
              ),
            ),
          ),

          // 3. Brand Emblem & Title Hero Area (Upper Safe Area)
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(top: screenHeight * 0.05),
                child: const AppBrandTitlePlaceholder(
                  logoSize: 76.0,
                  showBadge: true,
                  title: 'Paws and Found',
                  subtitle: 'Community Lost & Found Animal Recovery',
                ),
              ),
            ),
          ),

          // 4. Interactive Draggable Authentication Tray (Organism)
          Align(
            alignment: Alignment.bottomCenter,
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
