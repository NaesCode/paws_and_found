import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async' show unawaited;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/location_constants.dart';
import '../../../../core/services/geocoding_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../map/data/models/map_report_model.dart';
import '../../data/repositories/report_repository_impl.dart';
import '../../domain/repositories/report_repository.dart';
import '../../../../core/services/ai_pre_match_service.dart';
import '../../data/models/ai_match_candidate.dart';

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
  final GeocodingService _geocodingService;
  final AiPreMatchService _preMatchService;
  final ImagePicker _picker = ImagePicker();

  GeocodingService get geocoderService => _geocodingService;

  CameraReportController({
    ReportRepository? repository,
    LocationService? locationService,
    GeocodingService? geocodingService,
    AiPreMatchService? preMatchService,
  })  : _repository = repository ?? ReportRepositoryImpl(),
        _locationService = locationService ?? const GeolocatorLocationService(),
        _geocodingService = geocodingService ?? GeocoderProService(),
        _preMatchService = preMatchService ?? AiPreMatchServiceImpl();

  String _animalType = 'Canine';
  String _status = 'Stray';
  final TextEditingController descriptionController = TextEditingController();
  bool _isGpsAuto = true;
  double? _pinnedLat;
  double? _pinnedLng;
  double? _deviceLat;
  double? _deviceLng;
  bool _isFetchingLocation = false;
  Uint8List? _selectedImageBytes;
  String? _selectedImagePath;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _successReportId;
  String? _geocodedAddress;
  String? _linkedThreadId;
  String? _linkedThreadPetName;
  bool _isScanningAi = false;
  List<AiMatchCandidate> _aiCandidates = [];
  AiMatchCandidate? _selectedAiCandidate;

  // Getters
  String? get linkedThreadId => _linkedThreadId;
  String? get linkedThreadPetName => _linkedThreadPetName;
  bool get isScanningAi => _isScanningAi;
  List<AiMatchCandidate> get aiCandidates => _aiCandidates;
  AiMatchCandidate? get selectedAiCandidate => _selectedAiCandidate;
  String get animalType => _animalType;
  String get status => _status;
  bool get isGpsAuto => _isGpsAuto;
  double? get pinnedLat => _pinnedLat;
  double? get pinnedLng => _pinnedLng;
  double? get deviceLat => _deviceLat;
  double? get deviceLng => _deviceLng;
  bool get isFetchingLocation => _isFetchingLocation;
  LocationService get locationService => _locationService;
  Uint8List? get selectedImageBytes => _selectedImageBytes;
  String? get selectedImagePath => _selectedImagePath;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String? get successReportId => _successReportId;
  String? get geocodedAddress => _geocodedAddress;
  String? get resolvedLocationName => _geocodedAddress;

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

  void setThreadContext({String? threadId, String? petName}) {
    _linkedThreadId = threadId;
    _linkedThreadPetName = petName;
    notifyListeners();
  }

  void clearThreadContext() {
    _linkedThreadId = null;
    _linkedThreadPetName = null;
    _selectedAiCandidate = null;
    notifyListeners();
  }

  void selectAiCandidate(AiMatchCandidate candidate) {
    _selectedAiCandidate = candidate;
    _linkedThreadId = candidate.reportId;
    _linkedThreadPetName = candidate.petName;
    notifyListeners();
  }

  void clearAiCandidate() {
    _selectedAiCandidate = null;
    clearThreadContext();
  }

  Future<void> runAiPreMatchScan() async {
    if (_selectedImageBytes == null || _selectedImageBytes!.isEmpty) {
      _aiCandidates = [];
      _selectedAiCandidate = null;
      notifyListeners();
      return;
    }
    _isScanningAi = true;
    notifyListeners();
    try {
      final double lat = _pinnedLat ?? _deviceLat ?? LocationConstants.defaultLatitude;
      final double lng = _pinnedLng ?? _deviceLng ?? LocationConstants.defaultLongitude;
      final candidates = await _preMatchService.scanForCandidates(
        imageBytes: _selectedImageBytes!,
        lat: lat,
        lng: lng,
        animalType: _animalType,
      );
      _aiCandidates = candidates;
    } catch (e) {
      debugPrint('[CameraReportController] AI pre-match scan error: $e');
      _aiCandidates = [];
    } finally {
      _isScanningAi = false;
      notifyListeners();
    }
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
    _geocodedAddress = null;
    unawaited(_updateResolvedLocation(lat, lng));
    notifyListeners();
  }

  /// Resets pin to device GPS auto mode.
  void resetToAutoGps() {
    _pinnedLat = null;
    _pinnedLng = null;
    _isGpsAuto = true;
    _geocodedAddress = null;
    if (_deviceLat != null && _deviceLng != null) {
      unawaited(_updateResolvedLocation(_deviceLat!, _deviceLng!));
    }
    notifyListeners();
  }

  /// Proactively fetches device GPS coordinates on startup.
  Future<void> fetchDeviceLocation() async {
    _isFetchingLocation = true;
    notifyListeners();

    try {
      final pos = await _locationService.getCurrentPosition();
      if (pos != null) {
        _deviceLat = pos.latitude;
        _deviceLng = pos.longitude;
        if (_isGpsAuto && _pinnedLat == null) {
          unawaited(_updateResolvedLocation(pos.latitude, pos.longitude));
        }
      }
    } catch (e) {
      debugPrint('[CameraReportController] Device GPS fetch error: $e');
    } finally {
      _isFetchingLocation = false;
      notifyListeners();
    }
  }

  Future<void> _updateResolvedLocation(double lat, double lng) async {
    try {
      final name = await _geocodingService.reverseGeocode(lat, lng);
      if (name != null && name.isNotEmpty) {
        _geocodedAddress = name;
        notifyListeners();
      }
    } catch (_) {
      // Graceful fallback to raw coordinate readout
    }
  }

  /// Manually triggers reverse-geocoding on current active coordinates
  Future<void> reverseGeocodeCurrentCoords() async {
    final double? lat = pinnedLat ?? deviceLat;
    final double? lng = pinnedLng ?? deviceLng;

    if (lat != null && lng != null) {
      await _updateResolvedLocation(lat, lng);
    }
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
        unawaited(runAiPreMatchScan());
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
        unawaited(runAiPreMatchScan());
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
    unawaited(runAiPreMatchScan());
  }

  void clearPhoto() {
    _selectedImageBytes = null;
    _selectedImagePath = null;
    _aiCandidates = [];
    _selectedAiCandidate = null;
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

    if (_geocodedAddress == null || _geocodedAddress!.isEmpty) {
      await reverseGeocodeCurrentCoords();
    }

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

      // Default fallback coordinates: Prioritize custom pin, then detected device GPS, then Cebu default
      double lat = _pinnedLat ?? _deviceLat ?? LocationConstants.defaultLatitude;
      double lng = _pinnedLng ?? _deviceLng ?? LocationConstants.defaultLongitude;

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
          locationName: _geocodedAddress,
          linkedReportId: _linkedThreadId,
        );
        _successReportId = reportId;

        if (_linkedThreadId != null) {
          try {
            final client = Supabase.instance.client;
            final currentUserId = client.auth.currentUser?.id;
            if (currentUserId != null) {
              final petLabel = (_linkedThreadPetName != null && _linkedThreadPetName!.isNotEmpty)
                  ? 'for ${_linkedThreadPetName!} '
                  : '';
              final locationLabel = _geocodedAddress ?? 'Reported Area';
              await client.from('comments').insert({
                'post_id': _linkedThreadId,
                'user_id': currentUserId,
                'content': '🐾 Sighting reported ${petLabel}at $locationLabel!\nhttps://pawsandfound.org/report/$reportId',
              });
            }
          } catch (e) {
            debugPrint('[CameraReportController] Failed to auto-link comment: $e');
          }
        }

        // Register in active map reports so it immediately appears on the Community Animal Map
        MapReportModel.addReport(
          MapReportModel(
            id: reportId,
            reporterId: 'current_user',
            title: '$_animalType (${_status.toUpperCase()})',
            animalType: _animalType,
            description: descriptionController.text.trim(),
            status: _status.toLowerCase(),
            locationName: _geocodedAddress ?? 'Reported Area',
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
            locationName: _geocodedAddress ?? 'Pinned Location',
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
