import 'package:flutter/material.dart';
import '../../../../shared/atoms/app_logo.dart';
import '../../../../shared/molecules/app_overflow_menu.dart';

/// Pinned top header for the Profile screen.
///
/// Implemented as a real [PreferredSizeWidget] so [ProfileSetupPage] can
/// assign it to [Scaffold.appBar]. This lets it automatically inherit the
/// app-wide [AppBarTheme] (background color, title font, icon color,
/// status bar style) defined in [AppTheme.light].
class ProfileHeader extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onEditPressed;
  final VoidCallback? onSettingsPressed;

  const ProfileHeader({
    super.key,
    this.onEditPressed,
    this.onSettingsPressed,
  });

  /// Standard AppBar height — matches every other page's header height.
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      // Title inherits Nunito Sans 22px bold white from AppBarTheme automatically.
      title: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppLogo(size: 32),
          SizedBox(width: 10),
          Text('Profile Account'),
        ],
      ),

      // Three-dot overflow menu — standardized molecule.
      actions: [
        AppOverflowMenu(
          onEditPressed: onEditPressed,
          onSettingsPressed: onSettingsPressed,
        ),
      ],
    );
  }
}
