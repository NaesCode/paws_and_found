import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:paws_and_found/core/constants/app_assets.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';
import 'package:paws_and_found/core/theme/app_typography.dart';
import 'package:paws_and_found/shared/atoms/paw_button.dart';
import 'package:paws_and_found/shared/atoms/paw_text_field.dart';
import 'package:paws_and_found/features/feed/data/models/feed_post_model.dart';
import 'package:paws_and_found/features/feed/domain/repositories/feed_repository.dart';
import 'package:latlong2/latlong.dart';
import 'package:paws_and_found/core/constants/location_constants.dart';
import 'package:paws_and_found/core/services/geocoding_service.dart';
import 'package:paws_and_found/shared/organisms/location_pin_picker_sheet.dart';

class EditReportSheet extends StatefulWidget {
  final FeedPost report;
  final FeedRepository repository;

  const EditReportSheet({
    super.key,
    required this.report,
    required this.repository,
  });

  /// Static helper to launch the modal bottom sheet
  static Future<bool?> show({
    required BuildContext context,
    required FeedPost report,
    required FeedRepository repository,
    bool useSafeArea = true,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: useSafeArea,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditReportSheet(
        report: report,
        repository: repository,
      ),
    );
  }

  @override
  State<EditReportSheet> createState() => _EditReportSheetState();
}

class _EditReportSheetState extends State<EditReportSheet> {
  LatLng? _pinnedLocation;

  late final TextEditingController _petNameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;

  late String _selectedStatus;
  final List<String> _statusOptions = ['missing', 'found', 'stray'];
  
  late String _selectedSpecies;
  final List<String> _speciesOptions = ['Canine', 'Feline', 'Other'];

  Uint8List? _newImageBytes;
  String _imageExtension = 'jpg';
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final currentPetName = widget.report.petName.toLowerCase() == 'unknown pet'
        ? ''
        : widget.report.petName;
    _petNameController = TextEditingController(text: currentPetName);

    _descriptionController = TextEditingController(text: widget.report.description);
    _locationController = TextEditingController(text: widget.report.location);

    final currentStatus = widget.report.status.toLowerCase();
    _selectedStatus = _statusOptions.contains(currentStatus) ? currentStatus : 'missing';

    _selectedSpecies = _speciesOptions.firstWhere(
      (item) => item.toLowerCase() == widget.report.species.toLowerCase(),
      orElse: () => 'Other',
    );
  }

  Future<void> _handlePinOnMap() async {
    final LatLng? picked = await LocationPinPickerSheet.show(
      context: context,
      initialLocation: _pinnedLocation ?? LocationConstants.defaultLocation,
      pinStatus: _selectedStatus,
      title: 'Pin ${_selectedStatus.toUpperCase()} Animal on Map',
      subtitle: 'Tap anywhere on the map to set the exact sighting or missing pin',
    );
    if (picked != null) {
      setState(() {
        _pinnedLocation = picked;
      });
      try {
        final geocoding = GeocoderProService();
        final address = await geocoding.reverseGeocode(
          picked.latitude,
          picked.longitude,
        );
        if (address != null && address.trim().isNotEmpty) {
          _locationController.text = address.trim();
        } else {
          _locationController.text =
              '${picked.latitude.toStringAsFixed(4)}°, ${picked.longitude.toStringAsFixed(4)}°';
        }
      } catch (_) {
        if (_locationController.text.trim().isEmpty) {
          _locationController.text =
              '${picked.latitude.toStringAsFixed(4)}°, ${picked.longitude.toStringAsFixed(4)}°';
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pin updated: ${picked.latitude.toStringAsFixed(4)}° N, ${picked.longitude.toStringAsFixed(4)}° E',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _petNameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
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
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not select photo: $e';
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
                'Change Report Photo',
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

  Future<void> _handleSave() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      setState(() => _errorMessage = 'Description cannot be empty.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? uploadedPhotoUrl;

      if (_newImageBytes != null) {
        uploadedPhotoUrl = await widget.repository.uploadReportPhoto(
          _newImageBytes!,
          extension: _imageExtension,
        );
      }

      final hasLinkedPet = widget.report.petId != null;

      await widget.repository.updateReport(
        widget.report.id,
        description: description,
        locationName: _locationController.text.trim(),
        status: _selectedStatus,
        photoUrl: uploadedPhotoUrl,
        petId: widget.report.petId,
        petName: hasLinkedPet ? null : _petNameController.text.trim(),
        lat: _pinnedLocation?.latitude,
        lng: _pinnedLocation?.longitude,
        specie: hasLinkedPet ? null : _selectedSpecies,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: AppTypography.petName.copyWith(
              color: AppColors.darkCharcoal,
            ),
          ),
        ],
        Container(
          margin: const EdgeInsets.only(top: 12),
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: enabled ? AppColors.background2 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
              width: 1.0,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.firstWhere(
                (item) => item.toLowerCase() == value.toLowerCase(),
                orElse: () => items.first,
              ),
              isExpanded: true,
              icon: Icon(
                Icons.arrow_drop_down,
                color: enabled ? AppColors.darkCharcoal : AppColors.text3,
              ),
              style: AppTypography.bodyMedium.copyWith(
                color: enabled ? AppColors.darkCharcoal : AppColors.text3,
                fontWeight: FontWeight.w600,
              ),
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: enabled
                  ? (val) {
                      if (val != null) onChanged(val);
                    }
                  : null,
            ),
          ),
        ),
      ],
    );
  }
  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final hasExistingImage = widget.report.imageUrl.isNotEmpty &&
        (widget.report.imageUrl.startsWith('http://') ||
            widget.report.imageUrl.startsWith('https://'));
    final hasLinkedPet = widget.report.petId != null;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          automaticallyImplyLeading: false,
          toolbarHeight: 70,
          title: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit_note_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Edit Report',
                      style: AppTypography.profileTitle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Editing: ${widget.report.petName} ($_selectedSpecies)',
                      style: AppTypography.detailText.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Report Photo',
                      style: AppTypography.petName,
                    ),
                    const SizedBox(height: 8),

                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          GestureDetector(
                            onTap: _showImageSourcePicker,
                            child: Container(
                              width: double.infinity,
                              height: 170,
                              decoration: BoxDecoration(
                                color: AppColors.background2,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.25),
                                  width: 1.5,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _newImageBytes != null
                                  ? Image.memory(
                                      _newImageBytes!,
                                      fit: BoxFit.cover,
                                    )
                                  : hasExistingImage
                                      ? Image.network(
                                          widget.report.imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => Image.asset(
                                            AppAssets.petPlaceholder,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Image.asset(
                                          AppAssets.petPlaceholder,
                                          fit: BoxFit.cover,
                                        ),
                            ),
                          ),
                          Positioned(
                            bottom: 10,
                            right: 10,
                            child: GestureDetector(
                              onTap: _showImageSourcePicker,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                                    const SizedBox(width: 6),
                                    Text(
                                      _newImageBytes != null ? 'Replace Photo' : 'Change Photo',
                                      style: AppTypography.pillText.copyWith(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (_newImageBytes != null)
                            Positioned(
                              top: 10,
                              right: 10,
                              child: GestureDetector(
                                onTap: () => setState(() => _newImageBytes = null),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    /*const Text(
                      'Status',
                      style: AppTypography.petName,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: _statusOptions.map((status) {
                        final isSelected = _selectedStatus == status;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(status.toUpperCase()),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            labelStyle: AppTypography.pillText.copyWith(
                              color: isSelected ? Colors.white : AppColors.darkCharcoal,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                            onSelected: (selected) {
                              if (selected) setState(() => _selectedStatus = status);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),*/

                    Row(
                      children: [
                        const Text(
                          'Pet Name',
                          style: AppTypography.petName,
                        ),
                        if (hasLinkedPet) ...[ 
                          const SizedBox(width: 6),
                          const Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.text3),
                          const SizedBox(width: 4),
                          const Text(
                            '(Registered Pet)',
                            style: AppTypography.detailText,
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: hasLinkedPet ? 8 : 16),

                    PawTextField(
                      hintText: hasLinkedPet ? widget.report.petName : 'e.g. Mingmings, Catty, Kitchky',
                      controller: _petNameController,
                      enabled: !hasLinkedPet,
                    ),
                    if (hasLinkedPet)
                      const Padding(
                        padding: EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Linked to your registered pet. To change their name, go to Profile > Pets.',
                          style: AppTypography.detailText,
                        ),
                      ),

                    const SizedBox(height: 20), 
                    Row(
                      children: [
                        const Text(
                          'Species',
                          style: AppTypography.petName,
                        ),
                        if (hasLinkedPet) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.text3),
                          const SizedBox(width: 4),
                          const Text(
                            '(Registered Pet)',
                            style: AppTypography.detailText,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildDropdownField(
                      label: '',
                      value: _selectedSpecies,
                      items: _speciesOptions,
                      enabled: !hasLinkedPet,
                      onChanged: (val) => setState(() => _selectedSpecies = val),
                    ),
                    if (hasLinkedPet)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Linked to your registered pet. To change their name, go to Profile > Pets.',
                          style: AppTypography.detailText,
                        ),
                      ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Location Name / Address',
                          style: AppTypography.petName,
                        ),
                        TextButton.icon(
                          onPressed: _handlePinOnMap,
                          icon: const Icon(Icons.pin_drop_rounded, size: 16, color: AppColors.primary),
                          label: const Text(
                            'Pin on Map',
                            style: AppTypography.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    PawTextField(
                      hintText: 'e.g. Near IT Park, Lahug',
                      controller: _locationController,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.pin_drop_rounded, color: AppColors.primary),
                        tooltip: 'Pin on Animal Map',
                        onPressed: _handlePinOnMap,
                      ),
                    ),

                    if (_pinnedLocation != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Text(
                          'Pinned: ${_pinnedLocation!.latitude.toStringAsFixed(4)}° N, ${_pinnedLocation!.longitude.toStringAsFixed(4)}° E',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    const Text(
                      'Description',
                      style: AppTypography.petName,
                    ),
                    const SizedBox(height: 8),
                    PawTextField(
                      hintText: 'Enter details about the pet / sighting',
                      controller: _descriptionController,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: bottomInset > 0 ? bottomInset + 16 : 24,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Text(
                        _errorMessage!,
                        style: AppTypography.bodySmall.copyWith(color: Colors.red),
                      ),
                    ),
                  PawButton(
                    text: 'Save Changes',
                    color: AppColors.primary,
                    textColor: Colors.white,
                    isLoading: _isLoading,
                    onPressed: _handleSave,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}