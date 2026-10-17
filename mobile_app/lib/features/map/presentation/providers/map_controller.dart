import 'package:flutter/foundation.dart';
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

  MapController({MapRepository? repository})
      : _repository = repository ?? MapRepositoryImpl();

  List<MapReportEntity> _reports = [];
  MapReportEntity? _selectedReport;
  MapFilterType _currentFilter = MapFilterType.all;
  String? _selectedAnimalType;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<MapReportEntity> get reports => _reports;
  MapReportEntity? get selectedReport => _selectedReport;
  MapFilterType get currentFilter => _currentFilter;
  String? get selectedAnimalType => _selectedAnimalType;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Loads reports based on active filters.
  Future<void> loadReports() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await _repository.getReports(
        animalType: _selectedAnimalType,
        filterType: _currentFilter,
      );

      _reports = results;

      // Retain or select the first report if previously selected report is missing
      if (_selectedReport != null) {
        final match = results.where((r) => r.id == _selectedReport!.id);
        _selectedReport = match.isNotEmpty ? match.first : (results.isNotEmpty ? results.first : null);
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

  /// Selects a report pin by ID.
  void selectReportById(String id) {
    final match = _reports.where((r) => r.id == id);
    if (match.isNotEmpty) {
      _selectedReport = match.first;
      notifyListeners();
    }
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

  /// Re-centers the map view.
  void recenterMap() {
    // If a report is selected, keep it or reset to initial view
    if (_reports.isNotEmpty) {
      _selectedReport = _reports.first;
      notifyListeners();
    }
  }
}
