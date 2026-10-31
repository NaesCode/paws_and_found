import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/atoms/drag_handle.dart';
import '../../../../shared/atoms/paw_button.dart';
import '../../../../shared/atoms/paw_text_field.dart';
import '../../domain/entities/pet.dart';
import '../../domain/repositories/profile_repository.dart';

/// Modal bottom sheet for safely deleting a registered pet.
///
/// Requires:
/// 1. Confirmation by re-typing the pet's exact name.
/// 2. Selecting a structured deletion reason (for administrative / analytics data):
///    - "Pet is no longer ours"
///    - "Pet recently passed away"
///    - "Pet was long gone"
///    - "Other reasons:" (with custom free-text input)
/// 3. Upon deletion, cleans up associated reports, matches, and pet embeddings.
class DeletePetSheet extends StatefulWidget {
  final Pet pet;
  final ProfileRepository repository;

  const DeletePetSheet({
    super.key,
    required this.pet,
    required this.repository,
  });

  /// Helper method to present the sheet
  static Future<bool?> show({
    required BuildContext context,
    required Pet pet,
    required ProfileRepository repository,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DeletePetSheet(
        pet: pet,
        repository: repository,
      ),
    );
  }

  @override
  State<DeletePetSheet> createState() => _DeletePetSheetState();
}

class _DeletePetSheetState extends State<DeletePetSheet> {
  final TextEditingController _nameConfirmationController = TextEditingController();
  final TextEditingController _otherReasonController = TextEditingController();

  final List<String> _predefinedReasons = [
    'Pet is no longer ours',
    'Pet recently passed away',
    'Pet was long gone',
    'Other reasons',
  ];

  String _selectedReason = 'Pet is no longer ours';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameConfirmationController.dispose();
    _otherReasonController.dispose();
    super.dispose();
  }

  bool get _isNameConfirmed =>
      _nameConfirmationController.text.trim().toLowerCase() ==
      widget.pet.name.trim().toLowerCase();

  Future<void> _handleDelete() async {
    if (!_isNameConfirmed) {
      setState(() {
        _errorMessage = 'Please type "${widget.pet.name}" exactly to confirm.';
      });
      return;
    }

    if (_selectedReason == 'Other reasons' &&
        _otherReasonController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please specify the reason for removing ${widget.pet.name}.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final details = _selectedReason == 'Other reasons'
          ? _otherReasonController.text.trim()
          : null;

      await widget.repository.deletePet(
        widget.pet.petID,
        reason: _selectedReason,
        details: details,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to delete pet: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: bottomInset > 0 ? bottomInset + 16 : 32,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: DragHandle()),
            const SizedBox(height: 16),

            // Header Icon & Title
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_forever_rounded,
                    color: Colors.red.shade700,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Remove "${widget.pet.name}"',
                        style: const TextStyle(
                          fontFamily: 'Nunito Sans',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkCharcoal,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'This will delete pet records, active matches, and listings.',
                        style: TextStyle(
                          fontFamily: 'Ek Mukta',
                          fontSize: 12.5,
                          color: AppColors.text3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Divider(color: AppColors.text3),
            const SizedBox(height: 12),

            // Name confirmation instruction
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontFamily: 'Nunito Sans',
                  fontSize: 13.5,
                  color: AppColors.text1,
                ),
                children: [
                  const TextSpan(text: 'To confirm, please type the pet\'s name: '),
                  TextSpan(
                    text: widget.pet.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.contrast2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            const Text(
              'Pet Name *',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.text2),
            ),
            const SizedBox(height: 6),
            PawTextField(
              controller: _nameConfirmationController,
              hintText: 'Enter "${widget.pet.name}"',
              onChanged: (_) => setState(() => _errorMessage = null),
            ),
            const SizedBox(height: 18),

            // Deletion Reason section
            const Text(
              'Reason for removal:',
              style: TextStyle(
                fontFamily: 'Nunito Sans',
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.text1,
              ),
            ),
            const SizedBox(height: 8),

            ..._predefinedReasons.map((reason) {
              final isSelected = _selectedReason == reason;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedReason = reason;
                    _errorMessage = null;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Radio<String>(
                        value: reason,
                        groupValue: _selectedReason,
                        activeColor: AppColors.contrast2,
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedReason = val;
                              _errorMessage = null;
                            });
                          }
                        },
                      ),
                      Expanded(
                        child: Text(
                          reason,
                          style: TextStyle(
                            fontFamily: 'Nunito Sans',
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? AppColors.darkCharcoal : AppColors.text2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            // If "Other reasons" is selected, show details field
            if (_selectedReason == 'Other reasons') ...[
              const Text(
                'Other reasons details *',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.text2),
              ),
              const SizedBox(height: 6),
              PawTextField(
                controller: _otherReasonController,
                hintText: 'Please specify the reason...',
                maxLines: 2,
                onChanged: (_) => setState(() => _errorMessage = null),
              ),
            ],

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 16, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.text3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.text2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PawButton(
                    text: 'Confirm Delete',
                    onPressed: _isNameConfirmed ? _handleDelete : null,
                    color: AppColors.contrast2,
                    textColor: Colors.white,
                    isLoading: _isLoading,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

