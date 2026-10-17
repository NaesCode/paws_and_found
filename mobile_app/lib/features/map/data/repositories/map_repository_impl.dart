import '../../domain/entities/map_filter_type.dart';
import '../../domain/entities/map_report_entity.dart';
import '../../domain/repositories/map_repository.dart';
import '../datasources/map_remote_data_source.dart';

/// Concrete implementation of [MapRepository].
///
/// Bridges the Domain layer with the Data layer.
class MapRepositoryImpl implements MapRepository {
  final MapRemoteDataSource _dataSource;

  MapRepositoryImpl({MapRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? MapRemoteDataSourceImpl();

  @override
  Future<List<MapReportEntity>> getReports({
    double? latitude,
    double? longitude,
    double radiusMeters = 5000,
    String? animalType,
    MapFilterType filterType = MapFilterType.all,
  }) async {
    return await _dataSource.getNearbyReports(
      lat: latitude,
      lng: longitude,
      radiusMeters: radiusMeters,
      animalType: animalType,
      filterType: filterType,
    );
  }

  @override
  Future<MapReportEntity?> getReportById(String id) async {
    return await _dataSource.getReportById(id);
  }
}
