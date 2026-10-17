import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/atoms/drag_handle.dart';
import '../../../../shared/atoms/paw_button.dart';
import '../../../../shared/atoms/paw_text_field.dart';
import '../../domain/entities/user_profile.dart';

/// Modal bottom sheet allowing users to input/edit their name, contact number, address, and bio.
/// Utilizes shared design-system atoms: DragHandle, PawTextField, and PawButton.
class EditProfileSheet extends StatefulWidget {
  final UserProfile user;
  final bool isFirstTimeSetup;
  final Future<void> Function({
    required String name,
    required String phoneNumber,
    required String address,
    required String bio,
  }) onSave;
  final VoidCallback? onSkip;

  const EditProfileSheet({
    super.key,
    required this.user,
    this.isFirstTimeSetup = false,
    required this.onSave,
    this.onSkip,
  });

  /// Helper static method to show the sheet
  static Future<void> show({
    required BuildContext context,
    required UserProfile user,
    bool isFirstTimeSetup = false,
    required Future<void> Function({
      required String name,
      required String phoneNumber,
      required String address,
      required String bio,
    }) onSave,
    VoidCallback? onSkip,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditProfileSheet(
        user: user,
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
      await widget.onSave(
        name: name,
        phoneNumber: phone,
        address: address,
        bio: bio,
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
                  style: AppTypography.profileTitle.copyWith(fontSize: 22),
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
                const SizedBox(height: 20),

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

