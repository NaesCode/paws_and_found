import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:paws_and_found/core/constants/app_assets.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';
import 'package:paws_and_found/features/auth/domain/repositories/auth_repository.dart';
import 'package:paws_and_found/features/auth/presentation/widgets/auth_tray.dart';
import 'package:paws_and_found/shared/molecules/app_brand_title_placeholder.dart';

/// The authentication screen for Paws and Found.
///
/// Features a clinical surface background with the official SVG paw track pattern
/// watermark in the background, official vector brand logo in the upper hero area,
/// and the interactive [AuthTray] organism at the bottom.
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
          // 1. Clinical veterinary gradient background
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

          // 2. Official SVG Paw Background Pattern (Subtle animal rescue motif)
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.05,
                child: SvgPicture.asset(
                  AppAssets.authBackgroundSvg,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
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
                  showBadge: false,
                  useSvgLogo: true,
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
