import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/content_moderation_service.dart';
import '../../../../core/services/user_restriction_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/atoms/drag_handle.dart';
import '../../../../shared/atoms/paw_button.dart';
import '../../../../shared/atoms/paw_text_field.dart';
import '../../../../shared/molecules/community_warning_dialog.dart';
import '../../../../shared/molecules/sound_type_selector_tile.dart';
import '../../domain/entities/pet.dart';
import '../../domain/repositories/profile_repository.dart';
/// Modal bottom sheet allowing users to add a new registered pet.
///
/// Features input fields strictly matching the Supabase `public.pets` schema:
/// - Photo picker via [ImagePicker] -> uploads to Supabase Storage `animal-photos`
/// - Name (text, NOT NULL)
/// - Species (text, NOT NULL)
/// - Breed (text, optional)
/// - Color (text, optional)
/// - Description (text, optional)
/// - Status defaults to 'safe'
class AddPetSheet extends StatefulWidget {
  final ProfileRepository repository;

  const AddPetSheet({
    super.key,
    required this.repository,
  });

  /// Helper static method to show the sheet
  static Future<Pet?> show({
    required BuildContext context,
    required ProfileRepository repository,
  }) {
    return showModalBottomSheet<Pet>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddPetSheet(repository: repository),
    );
  }

  @override
  State<AddPetSheet> createState() => _AddPetSheetState();
}

class _AddPetSheetState extends State<AddPetSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _breedController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _customSpeciesController = TextEditingController();

  String _selectedSpecies = 'Dog';
  final List<String> _speciesOptions = ['Dog', 'Cat', 'Bird', 'Rabbit', 'Other'];

  static const int _maxPhotoSizeBytes = 2 * 1024 * 1024; // 2 MB limit (matches Supabase Storage bucket limit)
  final List<({Uint8List bytes, String extension})> _photos = [];
  final ImagePicker _picker = ImagePicker();

  String? _nameError;
  String? _customSpeciesError;
  String? _generalError;
  bool _isLoading = false;
  NotificationSoundType _selectedAlertSound = NotificationSoundType.cat;
  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _colorController.dispose();
    _descriptionController.dispose();
    _customSpeciesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        final List<XFile> files = await _picker.pickMultiImage();
        if (files.isNotEmpty) {
          final remaining = 5 - _photos.length;
          final toAdd = files.take(remaining);
          String? sizeWarning;

          for (final f in toAdd) {
            final bytes = await f.readAsBytes();
            if (bytes.lengthInBytes > _maxPhotoSizeBytes) {
              final mb = (bytes.lengthInBytes / (1024 * 1024)).toStringAsFixed(1);
              sizeWarning = 'Photo "${f.name}" ($mb MB) exceeds the 2 MB storage limit. Please choose a photo under 2 MB.';
              continue;
            }
            final ext = f.name.split('.').last.toLowerCase();
            final cleanExt = (ext == 'png' || ext == 'webp') ? ext : 'jpg';
            _photos.add((bytes: bytes, extension: cleanExt));
          }
          setState(() => _generalError = sizeWarning);
        }
      } else {
        final XFile? file = await _picker.pickImage(source: source);

        if (file != null && _photos.length < 5) {
          final bytes = await file.readAsBytes();
          if (bytes.lengthInBytes > _maxPhotoSizeBytes) {
            final mb = (bytes.lengthInBytes / (1024 * 1024)).toStringAsFixed(1);
            setState(() {
              _generalError = 'Captured photo ($mb MB) exceeds the 2 MB storage limit. Please choose a photo under 2 MB.';
            });
            return;
          }
          final ext = file.name.split('.').last.toLowerCase();
          final cleanExt = (ext == 'png' || ext == 'webp') ? ext : 'jpg';
          setState(() {
            _photos.add((bytes: bytes, extension: cleanExt));
            _generalError = null;
          });
        }
      }
    } catch (e) {
      setState(() {
        _generalError = 'Could not select photo: $e';
      });
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Pet Photo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkCharcoal,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: const Text('Choose from Gallery'),
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

  bool _validate() {
    bool isValid = true;
    setState(() {
      _nameError = null;
      _customSpeciesError = null;
      _generalError = null;

      if (_nameController.text.trim().isEmpty) {
        _nameError = 'Pet name is required';
        isValid = false;
      }

      if (_selectedSpecies == 'Other' && _customSpeciesController.text.trim().isEmpty) {
        _customSpeciesError = 'Please specify the species';
        isValid = false;
      }
    });
    return isValid;
  }

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();

    if (!_validate()) {
      return;
    }

    // 0. Account suspension check
    final isSuspended = await const UserRestrictionService().isUserSuspended();
    if (isSuspended) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.block_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('Account Suspended'),
            ],
          ),
          content: const Text(
            'Your account has been suspended by administration. Suspended accounts cannot register pets.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final name = _nameController.text.trim();
    final breed = _breedController.text.trim().isNotEmpty ? _breedController.text.trim() : null;
    final color = _colorController.text.trim().isNotEmpty ? _colorController.text.trim() : null;
    final description = _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null;

    final finalSpecies = _selectedSpecies == 'Other' && _customSpeciesController.text.trim().isNotEmpty
        ? _customSpeciesController.text.trim()
        : _selectedSpecies;

    // 0.1 Prohibited language check across pet textual fields
    final textToCheck = '$name ${breed ?? ""} ${color ?? ""} ${description ?? ""} $finalSpecies';
    final modResult = const ContentModerationService().checkContent(textToCheck);
    if (modResult.isBlocked) {
      final uid = Supabase.instance.client.auth.currentUser?.id ?? 'current_user';
      final record = await const UserRestrictionService().recordViolation(
        userId: uid,
        prohibitedWord: modResult.detectedWord ?? '',
      );
      if (!mounted) return;
      await CommunityWarningDialog.show(
        context: context,
        detectedWord: modResult.detectedWord ?? '',
        violationCount: record.count,
        isSuspended: record.isSuspended,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _generalError = null;
    });

    try {
      List<String> photoUrls = [];

      // 1. Upload photos to Supabase Storage (up to 5 for multi-angle AI embeddings)
      for (final photo in _photos) {
        final publicUrl = await widget.repository.uploadPetPhoto(
          photo.bytes,
          extension: photo.extension,
        );
        photoUrls.add(publicUrl);
      }

      // 2. Add pet record in Supabase
      final newPet = await widget.repository.addPet(
        name: name,
        species: finalSpecies,
        breed: breed,
        color: color,
        description: description,
        photoUrls: photoUrls,
        alertSound: _selectedAlertSound.id,
      );

      if (mounted) {
        Navigator.of(context).pop(newPet);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _generalError = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const DragHandle(),
                const SizedBox(height: 16),

                // Title
                const Text(
                  'Add New Pet',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Nunito Sans',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkCharcoal,
                  ),
                ),
                const SizedBox(height: 18),

                // Error Banner
                if (_generalError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _generalError!,
                            style: TextStyle(
                              color: Colors.red.shade800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Pet Photos (Up to 5 photos for multi-angle AI centroid embeddings)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pet Photos (Up to 5)',
                          style: TextStyle(
                            fontFamily: 'Nunito Sans',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkCharcoal,
                          ),
                        ),
                        Text(
                          '${_photos.length}/5 photos',
                          style: const TextStyle(
                            fontFamily: 'Ek Mukta',
                            fontSize: 12,
                            color: AppColors.text3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Adding multiple photos (face, body, side profile) trains AI to recognize your pet reliably.',
                      style: TextStyle(
                        fontFamily: 'Ek Mukta',
                        fontSize: 11.5,
                        color: AppColors.text3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 90,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ..._photos.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final photo = entry.value;
                            return Stack(
                              children: [
                                Container(
                                  width: 86,
                                  height: 86,
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Image.memory(photo.bytes, fit: BoxFit.cover),
                                ),
                                Positioned(
                                  top: 2,
                                  right: 12,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _photos.removeAt(idx)),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                          if (_photos.length < 5)
                            GestureDetector(
                              onTap: _showImageSourcePicker,
                              child: Container(
                                width: 86,
                                height: 86,
                                decoration: BoxDecoration(
                                  color: AppColors.background2,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(alpha: 0.4),
                                    width: 1.2,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.add_a_photo_outlined, color: AppColors.primary, size: 24),
                                    const SizedBox(height: 4),
                                    Text(
                                      _photos.isEmpty ? 'Add Photo' : 'Add More',
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Name Field (Required)
                PawTextField(
                  hintText: 'Pet Name *',
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  errorText: _nameError,
                ),
                const SizedBox(height: 14),

                // Species Selector (Required)
                const Text(
                  'Species',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkCharcoal,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8.0,
                  children: _speciesOptions.map((species) {
                    final isSelected = _selectedSpecies == species;
                    return ChoiceChip(
                      label: Text(species),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.grey.shade100,
                      labelStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.darkCharcoal,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedSpecies = species;
                            if (species != 'Other') {
                              _customSpeciesError = null;
                            }
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                if (_selectedSpecies == 'Other') ...[
                  const SizedBox(height: 10),
                  PawTextField(
                    hintText: 'Specify species (e.g. Hamster, Turtle, Ferret) *',
                    controller: _customSpeciesController,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    errorText: _customSpeciesError,
                    onChanged: (_) {
                      if (_customSpeciesError != null) {
                        setState(() => _customSpeciesError = null);
                      }
                    },
                  ),
                ],
                const SizedBox(height: 14),

                // Breed Field (Optional)
                PawTextField(
                  hintText: 'Breed (e.g. Golden Retriever, Calico)',
                  controller: _breedController,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),

                // Color Field (Optional)
                PawTextField(
                  hintText: 'Color (e.g. Orange / White, Black)',
                  controller: _colorController,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),

                // Description Field (Optional)
                PawTextField(
                  hintText: 'Description (e.g. Friendly, playful, distinct markings)',
                  controller: _descriptionController,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.done,
                  maxLines: 3,
                ),
                const SizedBox(height: 20),

                // Alert Sound Preference (per-pet)
                const Text(
                  'Notification Alert Sound',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkCharcoal,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Choose the sound that plays when you get updates about this pet.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.text3,
                  ),
                ),
                const SizedBox(height: 8),
                SoundTypeSelectorTile(
                  selectedType: _selectedAlertSound,
                  onTypeChanged: (type) => setState(() => _selectedAlertSound = type),
                ),
                const SizedBox(height: 24),

                // Submit Button
                PawButton(
                  text: 'Add Pet',
                  isLoading: _isLoading,
                  onPressed: _handleSubmit,
                  color: AppColors.primary,
                  textColor: Colors.white,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
