import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/atoms/drag_handle.dart';
import '../../../../shared/atoms/paw_button.dart';
import '../../../../shared/atoms/paw_text_field.dart';
import '../../domain/entities/pet.dart';
import '../../domain/repositories/profile_repository.dart';

/// Modal bottom sheet allowing pet owners to edit their registered pet details:
/// - Photo: replace or update photo (automatically triggers storage cleanup and AI re-embedding)
/// - Name (required)
/// - Species (choice chips: Dog, Cat, Bird, Rabbit, Other)
/// - Breed (optional)
/// - Color (optional)
/// - Description (optional)
class EditPetSheet extends StatefulWidget {
  final Pet pet;
  final ProfileRepository repository;

  const EditPetSheet({
    super.key,
    required this.pet,
    required this.repository,
  });

  /// Helper static method to show the sheet
  static Future<Pet?> show({
    required BuildContext context,
    required Pet pet,
    required ProfileRepository repository,
  }) {
    return showModalBottomSheet<Pet>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditPetSheet(
        pet: pet,
        repository: repository,
      ),
    );
  }

  @override
  State<EditPetSheet> createState() => _EditPetSheetState();
}

class _EditPetSheetState extends State<EditPetSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _breedController;
  late final TextEditingController _colorController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _customSpeciesController;

  late String _selectedSpecies;
  final List<String> _speciesOptions = ['Dog', 'Cat', 'Bird', 'Rabbit', 'Other'];

  Uint8List? _newImageBytes;
  String _imageExtension = 'jpg';
  bool _removePhoto = false;
  final ImagePicker _picker = ImagePicker();

  String? _nameError;
  String? _customSpeciesError;
  String? _generalError;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.pet.name);
    _breedController = TextEditingController(text: widget.pet.breed ?? '');
    _colorController = TextEditingController(text: widget.pet.color ?? '');
    _descriptionController = TextEditingController(text: widget.pet.description ?? '');

    final existingSpecies = widget.pet.species.trim();
    final matched = _speciesOptions.where(
      (opt) => opt.toLowerCase() == existingSpecies.toLowerCase() && opt != 'Other',
    );

    if (matched.isNotEmpty) {
      _selectedSpecies = matched.first;
      _customSpeciesController = TextEditingController();
    } else {
      _selectedSpecies = 'Other';
      _customSpeciesController = TextEditingController(
        text: existingSpecies.toLowerCase() == 'other' ? '' : existingSpecies,
      );
    }
  }

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
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        final ext = file.name.split('.').last.toLowerCase();
        setState(() {
          _newImageBytes = bytes;
          _imageExtension = (ext == 'png' || ext == 'webp') ? ext : 'jpg';
          _removePhoto = false;
          _generalError = null;
        });
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
                'Change Pet Photo',
                style: AppTypography.userName,
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

    setState(() {
      _isLoading = true;
      _generalError = null;
    });

    try {
      final name = _nameController.text.trim();
      final breed = _breedController.text.trim().isNotEmpty ? _breedController.text.trim() : null;
      final color = _colorController.text.trim().isNotEmpty ? _colorController.text.trim() : null;
      final description = _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null;

      final finalSpecies = _selectedSpecies == 'Other' && _customSpeciesController.text.trim().isNotEmpty
          ? _customSpeciesController.text.trim()
          : _selectedSpecies;

      List<String>? photoUrls;

      // 1. Upload new photo if user picked one
      if (_newImageBytes != null) {
        final publicUrl = await widget.repository.uploadPetPhoto(
          _newImageBytes!,
          extension: _imageExtension,
        );
        photoUrls = [publicUrl];
      } else if (_removePhoto) {
        photoUrls = [];
      }

      // 2. Commit update to repository
      final updatedPet = await widget.repository.updatePet(
        petId: widget.pet.petID,
        name: name,
        species: finalSpecies,
        breed: breed,
        color: color,
        description: description,
        photoUrls: photoUrls,
      );

      if (mounted) {
        Navigator.of(context).pop(updatedPet);
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final existingPhoto = widget.pet.photoURLs.isNotEmpty ? widget.pet.photoURLs.first : null;
    final hasExistingPhoto = !_removePhoto && existingPhoto != null && existingPhoto.isNotEmpty;

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
        padding: EdgeInsets.only(bottom: bottomInset),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Edit Pet Profile',
                          style: AppTypography.profileTitle,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Editing: ${widget.pet.name}',
                          style: AppTypography.detailText,
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.text3),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
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
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.red.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Pet Photo Picker Avatar
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      GestureDetector(
                        onTap: _showImageSourcePicker,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.background2,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              width: 2.0,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _newImageBytes != null
                              ? Image.memory(
                                  _newImageBytes!,
                                  fit: BoxFit.cover,
                                )
                              : hasExistingPhoto
                                  ? Image.network(
                                      existingPhoto,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Image.asset(
                                        AppAssets.petPlaceholder,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_a_photo_outlined, size: 36, color: AppColors.primary),
                                        SizedBox(height: 4),
                                        Text(
                                          'Add Photo',
                                          style: AppTypography.pillText,
                                        ),
                                      ],
                                    ),
                        ),
                      ),
                      // Edit badge pill
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: _showImageSourcePicker,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.camera_alt, size: 12, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  _newImageBytes != null ? 'Replace' : 'Change',
                                  style: AppTypography.pillText.copyWith(color: Colors.white, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Reset / Clear new image
                      if (_newImageBytes != null)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: GestureDetector(
                            onTap: () => setState(() => _newImageBytes = null),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Name Field (Required)
                const Text(
                  'Pet Name *',
                  style: AppTypography.petName,
                ),
                const SizedBox(height: 6),
                PawTextField(
                  hintText: 'Enter pet name',
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  errorText: _nameError,
                ),
                const SizedBox(height: 16),

                // Species Selector (Required)
                const Text(
                  'Species',
                  style: AppTypography.petName,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  children: _speciesOptions.map((species) {
                    final isSelected = _selectedSpecies == species;
                    return ChoiceChip(
                      label: Text(species),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.grey.shade100,
                      labelStyle: AppTypography.pillText.copyWith(
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
                const SizedBox(height: 16),

                // Breed Field (Optional)
                const Text(
                  'Breed',
                  style: AppTypography.petName,
                ),
                const SizedBox(height: 6),
                PawTextField(
                  hintText: 'Breed (e.g. Golden Retriever, Calico)',
                  controller: _breedController,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Color Field (Optional)
                const Text(
                  'Color',
                  style: AppTypography.petName,
                ),
                const SizedBox(height: 6),
                PawTextField(
                  hintText: 'Color (e.g. Orange / White, Black)',
                  controller: _colorController,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Description Field (Optional)
                const Text(
                  'Description',
                  style: AppTypography.petName,
                ),
                const SizedBox(height: 6),
                PawTextField(
                  hintText: 'Description (e.g. Friendly, playful, distinct markings)',
                  controller: _descriptionController,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.done,
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                // Submit Button
                PawButton(
                  text: 'Save Changes',
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
