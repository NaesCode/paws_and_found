import '../entities/map_filter_type.dart';
import '../entities/map_report_entity.dart';

/// Abstract contract for Map operations.
///
/// Adheres to Clean Architecture: defines WHAT data operations are possible
/// without implementing HOW they happen.
abstract class MapRepository {
  /// Fetches animal reports for display on the Community Animal Map.
  ///
  /// Supports geospatial proximity filtering, species categorization,
  /// and the "For You" contextual filter.
  Future<List<MapReportEntity>> getReports({
    double? latitude,
    double? longitude,
    double radiusMeters = 5000,
    String? animalType,
    MapFilterType filterType = MapFilterType.all,
  });

  /// Fetches complete details for a single selected map report.
  Future<MapReportEntity?> getReportById(String id);
}
