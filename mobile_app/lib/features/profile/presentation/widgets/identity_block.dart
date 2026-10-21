import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/user_profile.dart';
import 'paw_print_decoration.dart';

/// Renders the identity header: avatar, name, email, bio, and decorative paws.
class IdentityBlock extends StatelessWidget {
  final UserProfile user;
  final VoidCallback? onEditPressed;
  final VoidCallback? onAvatarPressed;

  const IdentityBlock({
    super.key,
    required this.user,
    this.onEditPressed,
    this.onAvatarPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background1,
      child: Stack(
        children: [
          // Background decorative paws
          const Positioned.fill(
            child: PawPrintDecoration(),
          ),

          Padding(
            padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 16.0, bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar: rounded square ~62x62 with radius 100
                Semantics(
                  button: true,
                  label: 'Change profile photo',
                  child: GestureDetector(
                    onTap: onAvatarPressed ?? onEditPressed,
                    child: Container(
                      margin: const EdgeInsets.only(top: 12.0, bottom: 10.0), // 👈 Nudges the avatar down
                      width: 65,
                      height: 65,
                      decoration: BoxDecoration(
                        color: AppColors.background2,
                        borderRadius: BorderRadius.circular(100),
                        image: (user.profilePhotoURL != null && user.profilePhotoURL!.isNotEmpty)
                            ? DecorationImage(
                                image: NetworkImage(user.profilePhotoURL!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: (user.profilePhotoURL == null || user.profilePhotoURL!.isEmpty)
                          ? const Icon(
                              Icons.person_rounded,
                              size: 36,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Name, Email, Bio text column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              user.name.isNotEmpty ? user.name : 'Your Name',
                              style: AppTypography.userName.copyWith(height: 0.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (onEditPressed != null)
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.text3),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              splashRadius: 18,
                              tooltip: 'Edit Profile',
                              onPressed: onEditPressed,
                            ),
                        ],
                      ),
                      Text(
                        user.email,
                        style: AppTypography.userEmail.copyWith(height: 0.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (user.bio != null && user.bio!.trim().isNotEmpty)
                            ? user.bio!
                            : 'Bio ---',
                        style: AppTypography.userBio,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

