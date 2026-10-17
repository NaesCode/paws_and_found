import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/atoms/drag_handle.dart';
import '../../../../shared/atoms/paw_button.dart';
import '../../../../shared/atoms/paw_text_field.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../data/repositories/profile_repository_impl.dart';

/// Modal bottom sheet allowing users to input/edit their name, contact number, address, bio, and photo.
/// Utilizes shared design-system atoms: DragHandle, PawTextField, and PawButton.
class EditProfileSheet extends StatefulWidget {
  final UserProfile user;
  final ProfileRepository? repository;
  final bool isFirstTimeSetup;
  final Future<void> Function({
    required String name,
    required String phoneNumber,
    required String address,
    required String bio,
    String? profilePhotoURL,
  }) onSave;
  final VoidCallback? onSkip;

  const EditProfileSheet({
    super.key,
    required this.user,
    this.repository,
    this.isFirstTimeSetup = false,
    required this.onSave,
    this.onSkip,
  });

  /// Helper static method to show the sheet
  static Future<void> show({
    required BuildContext context,
    required UserProfile user,
    ProfileRepository? repository,
    bool isFirstTimeSetup = false,
    required Future<void> Function({
      required String name,
      required String phoneNumber,
      required String address,
      required String bio,
      String? profilePhotoURL,
    }) onSave,
    VoidCallback? onSkip,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditProfileSheet(
        user: user,
        repository: repository,
        isFirstTimeSetup: isFirstTimeSetup,
        onSave: onSave,
        onSkip: onSkip,
      ),
    );
  }

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _bioController;

  Uint8List? _newPhotoBytes;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(text: widget.user.phoneNumber ?? '');
    _addressController = TextEditingController(text: widget.user.address ?? '');
    _bioController = TextEditingController(text: widget.user.bio ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _newPhotoBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose Profile Photo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkCharcoal,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();
    final bio = _bioController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please provide your name.');
      return;
    }

    if (widget.isFirstTimeSetup && (phone.isEmpty || address.isEmpty)) {
      setState(() => _errorMessage = 'Please provide both your contact number and address.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? photoUrl;
      if (_newPhotoBytes != null) {
        final repo = widget.repository ?? ProfileRepositoryImpl();
        photoUrl = await repo.uploadProfilePhoto(_newPhotoBytes!);
      }

      await widget.onSave(
        name: name,
        phoneNumber: phone,
        address: address,
        bio: bio,
        profilePhotoURL: photoUrl,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background1,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 24.0,
            right: 24.0,
            top: 12.0,
            bottom: bottomInset + 16.0,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: DragHandle()),
                const SizedBox(height: 16),

                // Title
                Text(
                  widget.isFirstTimeSetup ? 'Complete Your Profile' : 'Edit Profile',
                  style: AppTypography.profileTitle.copyWith(
                    fontSize: 22,
                    color: AppColors.darkCharcoal,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  widget.isFirstTimeSetup
                      ? 'Add your contact number and address so finders and pet owners can reach you.'
                      : 'Update your account information below.',
                  style: AppTypography.detailText,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Profile Avatar with Camera Button
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.background2,
                          shape: BoxShape.circle,
                          image: _newPhotoBytes != null
                              ? DecorationImage(
                                  image: MemoryImage(_newPhotoBytes!),
                                  fit: BoxFit.cover,
                                )
                              : (widget.user.profilePhotoURL != null &&
                                      widget.user.profilePhotoURL!.isNotEmpty)
                                  ? DecorationImage(
                                      image: NetworkImage(widget.user.profilePhotoURL!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                        ),
                        child: (_newPhotoBytes == null &&
                                (widget.user.profilePhotoURL == null ||
                                    widget.user.profilePhotoURL!.isEmpty))
                            ? const Icon(
                                Icons.person_rounded,
                                size: 48,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _showImageSourceDialog,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: TextButton(
                    onPressed: _showImageSourceDialog,
                    child: const Text(
                      'Change Photo',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                    ),
                  ),

                // Read-only email
                const Text(
                  'Email (Read-only)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.text3),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.background2.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    widget.user.email,
                    style: const TextStyle(fontSize: 14, color: AppColors.text3),
                  ),
                ),
                const SizedBox(height: 14),

                // Full Name
                const Text(
                  'Full Name *',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.text2),
                ),
                const SizedBox(height: 6),
                PawTextField(
                  controller: _nameController,
                  hintText: 'John Doe',
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),

                // Contact / Phone Number
                const Text(
                  'Contact Number *',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.text2),
                ),
                const SizedBox(height: 6),
                PawTextField(
                  controller: _phoneController,
                  hintText: 'e.g. 09123456789',
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),

                // Address
                const Text(
                  'Address *',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.text2),
                ),
                const SizedBox(height: 6),
                PawTextField(
                  controller: _addressController,
                  hintText: 'e.g. Street, Barangay, City, Province',
                  keyboardType: TextInputType.streetAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),

                // Bio
                const Text(
                  'Bio (Optional)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.text2),
                ),
                const SizedBox(height: 6),
                PawTextField(
                  controller: _bioController,
                  hintText: 'Tell the community about yourself...',
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 24),

                // Save button (PawButton atom)
                PawButton(
                  text: widget.isFirstTimeSetup ? 'Save & Continue' : 'Save Changes',
                  color: AppColors.primary,
                  textColor: AppColors.text1,
                  isLoading: _isLoading,
                  onPressed: _handleSave,
                ),

                if (widget.isFirstTimeSetup && widget.onSkip != null) ...[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _isLoading ? null : widget.onSkip,
                    child: const Text(
                      'Skip for now',
                      style: TextStyle(
                        color: AppColors.text3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

