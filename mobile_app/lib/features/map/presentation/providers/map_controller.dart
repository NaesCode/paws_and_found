import 'package:flutter/foundation.dart';

import 'package:latlong2/latlong.dart';

import '../../../../core/constants/location_constants.dart';

import '../../../../core/services/location_service.dart';

import '../../data/repositories/map_repository_impl.dart';

import '../../domain/entities/map_filter_type.dart';

import '../../domain/entities/map_report_entity.dart';

import '../../domain/repositories/map_repository.dart';



/// Presentation state controller for the Community Animal Map.

///

/// Follows Clean Architecture: coordinates domain use cases/repositories

/// and exposes reactive state to the UI via [ChangeNotifier].

class MapController extends ChangeNotifier {

  final MapRepository _repository;

  final LocationService _locationService;



  MapController({

    MapRepository? repository,

    LocationService? locationService,

  })  : _repository = repository ?? MapRepositoryImpl(),

        _locationService = locationService ?? const GeolocatorLocationService();



  List<MapReportEntity> _reports = [];

  MapReportEntity? _selectedReport;

  MapFilterType _currentFilter = MapFilterType.all;

  String? _selectedAnimalType;

  bool _isLoading = false;

  String? _errorMessage;

  LatLng? _userLocation;

  bool _isFetchingLocation = false;
  bool _disposed = false;

  @override
  void dispose(){
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  // Default coordinate: Cebu City (10.3157, 123.8854) matching localized Cebu database records

  static const LatLng defaultCenter = LocationConstants.defaultLocation;



  // Getters

  List<MapReportEntity> get reports => _reports;

  MapReportEntity? get selectedReport => _selectedReport;

  MapFilterType get currentFilter => _currentFilter;

  String? get selectedAnimalType => _selectedAnimalType;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  LatLng? get userLocation => _userLocation;

  bool get isFetchingLocation => _isFetchingLocation;

  LocationService get locationService => _locationService;



  LatLng get mapCenter => _userLocation ?? defaultCenter;



  /// Loads reports based on active filters and optional GPS coordinates.

  Future<void> loadReports() async {

    _isLoading = true;

    _errorMessage = null;

    notifyListeners();



    try {

      final results = await _repository.getReports(

        latitude: _userLocation?.latitude,

        longitude: _userLocation?.longitude,

        animalType: _selectedAnimalType,

        filterType: _currentFilter,

      );



      _reports = results;



      // Retain or select the first report if previously selected report is missing

      if (_selectedReport != null) {

        final match = results.where((r) => r.id == _selectedReport!.id);

        _selectedReport =

            match.isNotEmpty ? match.first : (results.isNotEmpty ? results.first : null);

      } else if (results.isNotEmpty) {

        _selectedReport = results.first;

      }

    } catch (e) {

      _errorMessage = e.toString();

    } finally {

      _isLoading = false;

      notifyListeners();

    }

  }



  /// Obtains current GPS coordinates using [LocationService].

  ///

  /// Checks last known device position first for immediate responsiveness,

  /// followed by high-accuracy live GPS query.

  Future<LatLng?> fetchUserLocation() async {

    _isFetchingLocation = true;

    notifyListeners();



    try {

      final lastKnown = await _locationService.getLastKnownPosition();

      if (lastKnown != null) {

        _userLocation = LatLng(lastKnown.latitude, lastKnown.longitude);

        notifyListeners();

      }



      final position = await _locationService.getCurrentPosition();

      if (position != null) {

        _userLocation = LatLng(position.latitude, position.longitude);

        await loadReports();

        notifyListeners();

        return _userLocation;

      }

      return _userLocation;

    } catch (e) {

      debugPrint('[MapController] Location fetch failed: $e');

      return _userLocation;

    } finally {

      _isFetchingLocation = false;

      notifyListeners();

    }

  }



  /// Registers a dynamic report (e.g. from notification navigation) and selects it immediately.

  void registerAndSelectReport(MapReportEntity report) {

    final idx = _reports.indexWhere((r) => r.id == report.id);

    if (idx != -1) {

      _reports[idx] = report;

    } else {

      _reports.insert(0, report);

    }

    _selectedReport = report;

    notifyListeners();

  }



  /// Selects a report pin by ID with flexible matching (exact, prefix, or suffix).

  void selectReportById(String id) {

    final cleanId = id.replaceAll('#', '').toLowerCase();

    final match = _reports.where((r) {

      final rId = r.id.toLowerCase();

      return rId == cleanId ||

          rId.startsWith(cleanId) ||

          rId.endsWith(cleanId) ||

          cleanId.startsWith(rId);

    });

    if (match.isNotEmpty) {

      _selectedReport = match.first;

      notifyListeners();

    }

  }



  /// Selects a report entity directly.

  void selectReport(MapReportEntity report) {

    _selectedReport = report;

    notifyListeners();

  }



  /// Sets the active filter type ('all' or 'for_you').

  void setFilter(MapFilterType filter) {

    if (_currentFilter != filter) {

      _currentFilter = filter;

      loadReports();

    }

  }



  /// Sets the active animal species category filter (e.g., 'Canine', 'Feline', or null for all).

  void setAnimalType(String? animalType) {

    if (_selectedAnimalType != animalType) {

      _selectedAnimalType = animalType;

      loadReports();

    }

  }



  /// Deselects the active report card.

  void clearSelection() {

    _selectedReport = null;

    notifyListeners();

  }



  /// Re-centers the map view to user location or default.

  void recenterMap() {

    clearSelection();

  }

}

