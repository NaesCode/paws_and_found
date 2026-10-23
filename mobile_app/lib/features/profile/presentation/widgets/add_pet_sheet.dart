import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/atoms/drag_handle.dart';
import '../../../../shared/atoms/paw_button.dart';
import '../../../../shared/atoms/paw_text_field.dart';
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

  String _selectedSpecies = 'Dog';
  final List<String> _speciesOptions = ['Dog', 'Cat', 'Bird', 'Rabbit', 'Other'];

  Uint8List? _selectedImageBytes;
  String? _imageExtension = 'jpg';
  final ImagePicker _picker = ImagePicker();

  String? _nameError;
  String? _generalError;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _colorController.dispose();
    _descriptionController.dispose();
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
          _selectedImageBytes = bytes;
          _imageExtension = (ext == 'png' || ext == 'webp') ? ext : 'jpg';
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
      _generalError = null;

      if (_nameController.text.trim().isEmpty) {
        _nameError = 'Pet name is required';
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

      List<String> photoUrls = [];

      // 1. Upload photo to Supabase Storage if user selected an image
      if (_selectedImageBytes != null) {
        final publicUrl = await widget.repository.uploadPetPhoto(
          _selectedImageBytes!,
          extension: _imageExtension ?? 'jpg',
        );
        photoUrls.add(publicUrl);
      }

      // 2. Add pet record in Supabase
      final newPet = await widget.repository.addPet(
        name: name,
        species: _selectedSpecies,
        breed: breed,
        color: color,
        description: description,
        photoUrls: photoUrls,
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

                // Pet Photo Picker Avatar
                Center(
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: _showImageSourcePicker,
                        child: Container(
                          width: 104,
                          height: 104,
                          decoration: BoxDecoration(
                            color: AppColors.background2,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _selectedImageBytes != null
                              ? Image.memory(
                                  _selectedImageBytes!,
                                  fit: BoxFit.cover,
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo_outlined, size: 36, color: AppColors.primary),
                                    SizedBox(height: 4),
                                    Text(
                                      'Add Photo',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      if (_selectedImageBytes != null)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedImageBytes = null),
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
                          setState(() => _selectedSpecies = species);
                        }
                      },
                    );
                  }).toList(),
                ),
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
