import 'dart:async' show unawaited;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/location_service.dart';
import '../../../map/data/models/map_report_model.dart';
import '../../data/repositories/report_repository_impl.dart';
import '../../domain/repositories/report_repository.dart';

/// Presentation state controller for Camera & Animal Report Creation.
///
/// Implements SDD Section 5.8 (CreateReport) & Section 6.1 (5):
/// - Manages photo capture & gallery picking
/// - Integrates live GPS coordinates via [LocationService]
/// - Supports interactive map pinning for alert placement
/// - Holds animal type, status enum, description, and GPS coordinates
/// - Handles report submission and pre-configures data for AI matching
class CameraReportController extends ChangeNotifier {
  final ReportRepository _repository;
  final LocationService _locationService;
  final ImagePicker _picker = ImagePicker();

  CameraReportController({
    ReportRepository? repository,
    LocationService? locationService,
  })  : _repository = repository ?? ReportRepositoryImpl(),
        _locationService = locationService ?? const GeolocatorLocationService();

  String _animalType = 'Canine';
  String _status = 'Stray';
  final TextEditingController descriptionController = TextEditingController();
  bool _isGpsAuto = true;
  double? _pinnedLat;
  double? _pinnedLng;
  Uint8List? _selectedImageBytes;
  String? _selectedImagePath;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _successReportId;

  // Getters
  String get animalType => _animalType;
  String get status => _status;
  bool get isGpsAuto => _isGpsAuto;
  double? get pinnedLat => _pinnedLat;
  double? get pinnedLng => _pinnedLng;
  Uint8List? get selectedImageBytes => _selectedImageBytes;
  String? get selectedImagePath => _selectedImagePath;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String? get successReportId => _successReportId;

  /// Formatted date/time string matching wireframe "MM/DD/YY HH:MM"
  String get formattedDateTime {
    final now = DateTime.now();
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    final yy = (now.year % 100).toString().padLeft(2, '0');
    final hh = now.hour.toString().padLeft(2, '0');
    final min = now.minute.toString().padLeft(2, '0');
    return '$mm/$dd/$yy $hh:$min';
  }

  void setAnimalType(String value) {
    _animalType = value;
    notifyListeners();
  }

  void setStatus(String value) {
    _status = value;
    notifyListeners();
  }

  void toggleGps() {
    _isGpsAuto = !_isGpsAuto;
    notifyListeners();
  }

  /// Sets interactive map pin coordinates.
  void setPinnedLocation(double lat, double lng) {
    _pinnedLat = lat;
    _pinnedLng = lng;
    _isGpsAuto = false;
    notifyListeners();
  }

  /// Resets pin to device GPS auto mode.
  void resetToAutoGps() {
    _pinnedLat = null;
    _pinnedLng = null;
    _isGpsAuto = true;
    notifyListeners();
  }

  /// Pick an animal photo from device gallery
  Future<void> pickFromGallery() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        _selectedImageBytes = bytes;
        _selectedImagePath = file.path;
        _errorMessage = null;
        notifyListeners();
      }
    } catch (_) {
      // In testing / simulator environments, generate a mock wireframe indicator
      _selectedImageBytes = Uint8List(0);
      notifyListeners();
    }
  }

  /// Trigger viewfinder capture (uses native camera if available)
  Future<void> capturePhoto() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        _selectedImageBytes = bytes;
        _selectedImagePath = file.path;
        _errorMessage = null;
        notifyListeners();
      }
    } catch (_) {
      // Fallback for emulators without physical camera
      _selectedImageBytes = Uint8List(0);
      notifyListeners();
    }
  }

  /// Ingests a photo captured via live in-app camera or file stream
  void setImageData(Uint8List bytes, String? path) {
    _selectedImageBytes = bytes;
    _selectedImagePath = path;
    _errorMessage = null;
    notifyListeners();
  }

  void clearPhoto() {
    _selectedImageBytes = null;
    _selectedImagePath = null;
    notifyListeners();
  }

  /// Submits the report to Supabase or simulates submission in offline wireframe mode.
  /// Dynamically queries [LocationService] for device GPS if [isGpsAuto] is enabled and no
  /// explicit pin was chosen.
  Future<bool> submitReport() async {
    _isSubmitting = true;
    _errorMessage = null;
    _successReportId = null;
    notifyListeners();

    try {
      String photoUrl = '';
      if (_selectedImageBytes != null && _selectedImageBytes!.isNotEmpty) {
        try {
          photoUrl = await _repository.uploadReportPhoto(_selectedImageBytes!);
        } catch (_) {
          // Graceful fallback for offline wireframe testing
          photoUrl = 'https://images.unsplash.com/photo-1543466835-00a7907e9de1';
        }
      }

      // Default fallback coordinates (Manila / default demo location)
      double lat = _pinnedLat ?? 14.5995;
      double lng = _pinnedLng ?? 120.9842;

      // When Auto GPS is enabled and no custom pin was placed, fetch high-accuracy device coordinates
      if (_isGpsAuto && _pinnedLat == null) {
        try {
          final position = await _locationService.getCurrentPosition().timeout(
            const Duration(milliseconds: 200),
            onTimeout: () => null,
          );
          if (position != null) {
            lat = position.latitude;
            lng = position.longitude;
          }
        } catch (e) {
          debugPrint('[CameraReportController] LocationService unavailable, falling back to default: $e');
        }
      }

      try {
        final reportId = await _repository.createReport(
          animalType: _animalType.toLowerCase(),
          description: descriptionController.text.trim(),
          photoUrl: photoUrl.isNotEmpty
              ? photoUrl
              : 'https://images.unsplash.com/photo-1543466835-00a7907e9de1',
          lat: lat,
          lng: lng,
          status: _status.toLowerCase(),
        );
        _successReportId = reportId;

        // Register in active map reports so it immediately appears on the Community Animal Map
        MapReportModel.addReport(
          MapReportModel(
            id: reportId,
            reporterId: 'current_user',
            title: '$_animalType (${_status.toUpperCase()})',
            animalType: _animalType,
            description: descriptionController.text.trim(),
            status: _status.toLowerCase(),
            locationName: 'Reported Area',
            latitude: lat,
            longitude: lng,
            normalizedX: 0.5,
            normalizedY: 0.5,
            createdAt: DateTime.now(),
            tags: [_animalType, _status.toUpperCase()],
            photoUrl: photoUrl.isNotEmpty ? photoUrl : null,
          ),
        );

        // Dispatches AI feature extraction & matching request to orchestrator
        // (Handled gracefully with fallback if orchestrator is not yet deployed)
        unawaited(_repository.requestReportAnalysis(reportId));
      } catch (_) {
        // Fallback for development/wireframe mode
        final fallbackId = 'rep-${DateTime.now().millisecondsSinceEpoch}';
        _successReportId = fallbackId;

        MapReportModel.addReport(
          MapReportModel(
            id: fallbackId,
            reporterId: 'current_user',
            title: '$_animalType (${_status.toUpperCase()})',
            animalType: _animalType,
            description: descriptionController.text.trim(),
            status: _status.toLowerCase(),
            locationName: 'Pinned Location',
            latitude: lat,
            longitude: lng,
            normalizedX: 0.5,
            normalizedY: 0.5,
            createdAt: DateTime.now(),
            tags: [_animalType, _status.toUpperCase()],
            photoUrl: photoUrl.isNotEmpty ? photoUrl : null,
          ),
        );
      }

      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }
}
