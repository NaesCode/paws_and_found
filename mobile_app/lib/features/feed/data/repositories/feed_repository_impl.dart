import '../../../../core/services/geocoding_service.dart';
import '../../domain/entities/feed_post.dart';
import '../../domain/repositories/feed_repository.dart';
import '../datasources/feed_mock_data.dart';
import '../datasources/feed_remote_data_source.dart';
import '../models/feed_post_model.dart';

class FeedRepositoryImpl implements FeedRepository {
  final FeedRemoteDataSource _remoteDataSource;
  final GeocodingService _geocodingService;

  FeedRepositoryImpl({
    FeedRemoteDataSource? remoteDataSource,
    GeocodingService? geocodingService,
  }) : _remoteDataSource = remoteDataSource ?? FeedRemoteDataSourceImpl(),
       _geocodingService = geocodingService ?? GeocoderProService();

  List<PetPostModel> _joinAndMapReports(
    List<Map<String, dynamic>> rawPostList,
  ) {
    return rawPostList.map((postRaw) {
      final Map<String, dynamic> userRaw = mockUsers.firstWhere(
        (user) => user['id'] == postRaw['user_id'],
        orElse: () => <String, dynamic>{},
      );

      return PetPostModel.fromJoinedData(
        postRaw,
        userRaw.isEmpty ? null : userRaw,
      );
    }).toList();
  }

  /// Detects whether the current location string represents raw machine coordinates
  /// (e.g. "10.3181, 123.9052") or generic fallbacks that should be resolved to real place names.
  bool _isCoordinateLocation(String loc) {
    final trimmed = loc.trim();
    final coordRegex = RegExp(r'^-?\d+(\.\d+)?,\s*-?\d+(\.\d+)?$');
    return coordRegex.hasMatch(trimmed) ||
        trimmed == 'Nearby Location' ||
        trimmed == 'Cebu, Philippines' ||
        trimmed.startsWith('01010000');
  }

  /// Resolves human-readable addresses for reports that only contain numeric coordinates.
  /// Relies on [GeocoderProService] in-memory caching to avoid redundant OpenStreetMap calls.
  Future<List<FeedPost>> _resolveLocationNames(List<FeedPost> posts) async {
    final updated = <FeedPost>[];
    for (final post in posts) {
      if (_isCoordinateLocation(post.location) &&
          post.latitude != null &&
          post.longitude != null) {
        try {
          final resolved = await _geocodingService.reverseGeocode(
            post.latitude!,
            post.longitude!,
          );
          if (resolved != null && resolved.isNotEmpty) {
            updated.add(post.copyWithLocation(resolved));
            continue;
          }
        } catch (_) {
          // Gracefully retain original location string on network timeout/failure
        }
      }
      updated.add(post);
    }
    return updated;
  }

  @override
  Future<List<FeedPost>> getGeneralReports() async {
    // 1. Attempt to fetch live community reports from the Supabase view
    try {
      final remoteRows = await _remoteDataSource.getFeedReports();
      if (remoteRows.isNotEmpty) {
        final initialPosts = remoteRows.map(PetPostModel.fromJson).toList();
        return await _resolveLocationNames(initialPosts);
      }
    } catch (_) {
      // Fallback below
    }

    // 2. Fallback to calibrated local mock data if offline or remote returns empty
    await Future.delayed(const Duration(milliseconds: 300));
    final mockMapped = _joinAndMapReports(mockPosts);
    return await _resolveLocationNames(mockMapped);
  }

  @override
  Future<List<FeedPost>> getPersonalReports(String currentUserId) async {
    // 1. Attempt to fetch user's live reports from Supabase
    try {
      final remoteRows = await _remoteDataSource.getUserFeedReports(
        currentUserId,
      );
      if (remoteRows.isNotEmpty) {
        final initialPosts = remoteRows.map(PetPostModel.fromJson).toList();
        return await _resolveLocationNames(initialPosts);
      }
    } catch (_) {
      // Fallback below
    }

    // 2. Fallback to calibrated local mock data
    await Future.delayed(const Duration(milliseconds: 300));
    final List<Map<String, dynamic>> userSpecificPosts = mockPosts
        .where((post) => post['user_id'] == currentUserId)
        .toList();

    final mockMapped = _joinAndMapReports(userSpecificPosts);
    return await _resolveLocationNames(mockMapped);
  }
}
