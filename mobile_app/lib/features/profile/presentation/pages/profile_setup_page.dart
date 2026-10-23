import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/pet.dart';
import '../../domain/repositories/profile_repository.dart';
import '../widgets/profile_header.dart';
import '../widgets/identity_block.dart';
import '../widgets/profile_details.dart';
import '../widgets/edit_profile_sheet.dart';
import '../widgets/add_pet_sheet.dart';
import '../../../../core/services/location_service.dart';
import '../widgets/paws_profile_section.dart';
import '../widgets/report_missing_sheet.dart';

/// The Profile Account screen.
/// Serves as both the user's permanent profile screen and the onboarding
/// setup destination when a user logs in for the first time.
class ProfileSetupPage extends StatefulWidget {
  final ProfileRepository? repository;
  final LocationService? locationService;

  const ProfileSetupPage({
    super.key,
    this.repository,
    this.locationService,
  });

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  late final ProfileRepository _repository;

  UserProfile? _user;
  List<Pet> _pets = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasPromptedOnboarding = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ProfileRepositoryImpl();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await _repository.getProfile();
      final pets = await _repository.getPets();

      if (mounted) {
        setState(() {
          _user = profile;
          _pets = pets;
          _isLoading = false;
        });

        // If the profile is incomplete, prompt onboarding modal once
        if (!_hasPromptedOnboarding && !profile.isProfileComplete) {
          _hasPromptedOnboarding = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showEditProfile(isFirstTimeSetup: true);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        // Fallback: If offline or initial load fails, check local Supabase session
        final session = Supabase.instance.client.auth.currentSession;
        final email = session?.user.email ?? 'user@pawsandfound.org';
        final name = (session?.user.userMetadata?['name'] as String?) ?? 'Pet Owner';

        setState(() {
          _user ??= UserProfile(
            userID: session?.user.id ?? '',
            name: name,
            email: email,
          );
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _showEditProfile({bool isFirstTimeSetup = false}) {
    if (_user == null) return;

    EditProfileSheet.show(
      context: context,
      user: _user!,
      repository: _repository,
      isFirstTimeSetup: isFirstTimeSetup,
      onSkip: () => Navigator.of(context).pop(),
      onSave: ({
        required String name,
        required String phoneNumber,
        required String address,
        required String bio,
        String? profilePhotoURL,
      }) async {
        final updated = await _repository.updateProfile(
          name: name,
          phoneNumber: phoneNumber,
          address: address,
          bio: bio,
          profilePhotoURL: profilePhotoURL,
        );

        if (mounted) {
          setState(() {
            _user = updated;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isFirstTimeSetup
                  ? 'Profile setup complete! Welcome to Paws and Found.'
                  : 'Profile successfully updated.'),
              backgroundColor: AppColors.primary,
              action: isFirstTimeSetup
                  ? SnackBarAction(
                      label: 'Go to Home',
                      textColor: Colors.white,
                      onPressed: () => context.go('/home'),
                    )
                  : null,
            ),
          );
        }
      },
    );
  }

  Future<void> _handlePetStatusToggle(Pet pet) async {
    final isSafe = pet.status == PetStatus.safe;

    if (isSafe) {
      // 1. Report Missing Flow via ReportMissingSheet (with LocationService GPS)
      final result = await ReportMissingSheet.show(
        context: context,
        pet: pet,
        locationService: widget.locationService,
      );

      if (result == null) return; // User cancelled

      setState(() => _isLoading = true);
      try {
        await _repository.reportPetMissing(
          pet.petID,
          lat: result.latitude,
          lng: result.longitude,
          note: result.note,
        );

        final updatedPets = await _repository.getPets();
        if (mounted) {
          setState(() {
            _pets = updatedPets;
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${pet.name} reported missing. Community alert active!'),
              backgroundColor: AppColors.contrast2,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'View Map',
                textColor: Colors.white,
                onPressed: () {
                  context.push('/map');
                },
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to report pet missing: $e'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      }
    } else {
      // 2. Mark as Safe Flow with Confirmation Dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Mark "${pet.name}" as Safe?'),
          content: Text(
            'Did you find ${pet.name}? Marking them safe will update their status and close any active missing alerts on the community map.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel', style: TextStyle(color: AppColors.text3)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(
                'Confirm Safe',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        setState(() => _isLoading = true);
        try {
          await _repository.markPetSafe(pet.petID);
          final updatedPets = await _repository.getPets();
          if (mounted) {
            setState(() {
              _pets = updatedPets;
              _isLoading = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Wonderful news! ${pet.name} is marked safe.'),
                backgroundColor: AppColors.primary,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update pet status: $e'),
                backgroundColor: Colors.red.shade700,
              ),
            );
          }
        }
      }
    }
  }

  Future<void> _showAddPetSheet() async {
    final newPet = await AddPetSheet.show(
      context: context,
      repository: _repository,
    );

    if (newPet != null && mounted) {
      // Re-fetch pet list directly from Supabase
      final updatedPets = await _repository.getPets();
      if (!mounted) return;
      setState(() {
        _pets = updatedPets;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully registered ${newPet.name}!'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background1,
      appBar: ProfileHeader(
        onEditPressed: () => _showEditProfile(isFirstTimeSetup: false),
      ),
      body: _isLoading && _user == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _loadProfileData,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Top White Identity & Details Block
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Optional setup banner for first-time users
                        if (_user != null && !_user!.isProfileComplete)
                          Container(
                            color: AppColors.accentOrange.withValues(alpha: 0.12),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, size: 20, color: AppColors.accentOrange),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'Finish setting up your account by completing your contact & address.',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.darkCharcoal,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _showEditProfile(isFirstTimeSetup: true),
                                  child: const Text(
                                    'Setup',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.accentOrange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (_errorMessage != null)
                          Container(
                            color: Colors.red.shade50,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, size: 18, color: Colors.red.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Could not reach backend: $_errorMessage',
                                    style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.refresh, size: 18),
                                  onPressed: _loadProfileData,
                                ),
                              ],
                            ),
                          ),

                        // Identity Section
                        IdentityBlock(
                          user: _user!,
                          onEditPressed: () => _showEditProfile(isFirstTimeSetup: false),
                        ),

                        // Details Section (Divider, Address, Contact, Registered Pets, Add Pet pill)
                        ProfileDetails(
                          user: _user!,
                          registeredPetsCount: _pets.length,
                          onAddPetPressed: _showAddPetSheet,
                        ),
                      ],
                    ),
                  ),

                  // Gray "Paws Profile" Section (Extends to fill viewport)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: PawsProfileSection(
                      pets: _pets,
                      isLoading: _isLoading && _pets.isEmpty,
                      onStatusToggle: _handlePetStatusToggle,
                      onAddPetPressed: _showAddPetSheet,
                      onPetTap: (pet) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Pet details for ${pet.name} coming soon.'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
