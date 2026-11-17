import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Screen template defining the layout structure for Settings and configuration pages.
///
/// Adheres strictly to Atomic Design (lib/shared/templates/).
/// Pure dumb template wrapping a standard app bar and scrollable content body.
class SettingsScreenTemplate extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? bottomNavigationBar;
  final VoidCallback? onBackPressed;

  const SettingsScreenTemplate({
    super.key,
    this.title = 'Settings',
    required this.body,
    this.bottomNavigationBar,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceMuted,
      appBar: AppBar(
        title: Text(title),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: onBackPressed ?? () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: body,
        ),
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
