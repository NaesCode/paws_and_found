import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';

/// Placeholder page for the main dashboard/home feed.
/// Returning users are routed here after a successful login.
///
/// TODO: Replace this placeholder with the full Dashboard feature
///       (map view, lost/found pet feed, etc.) when implemented.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // TODO: Remove this AppBar when proper navigation/settings are implemented
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout, color: AppColors.accentOrange),
            label: const Text(
              'Logout',
              style: TextStyle(color: AppColors.accentOrange, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.pets_rounded,
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              const Text(
                'Paws and Found',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Caveat',
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkCharcoal,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Welcome back! The main dashboard will be here — '
                'pet map, lost & found feed, and more.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 40),
              // TODO: Replace with real dashboard content when feature is implemented
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.construction_rounded, color: AppColors.primary),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '🚧 Under Construction — Dashboard coming soon.',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

