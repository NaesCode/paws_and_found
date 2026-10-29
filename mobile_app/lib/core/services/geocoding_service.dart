import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geocoder_pro/geocoder_pro.dart';
import 'package:http/http.dart' as http;

/// Contract for application-wide geocoding and spatial calculation operations.
///
/// Follows Clean Architecture rules: resides in `lib/core/services/`
/// for cross-feature reusability (feed, report, map, notifications).
abstract class GeocodingService {
  /// Converts latitude and longitude into a concise human-readable location
  /// string (e.g. "Kasambagan, Cebu City" or "Lahug, Cebu City").
  ///
  /// Returns `null` if reverse geocoding is unavailable or offline.
  Future<String?> reverseGeocode(double lat, double lng);

  /// Resolves an address or locality search string to geographic coordinates.
  ///
  /// Returns `null` if the query yields no results or network fails.
  Future<GeoCoordinates?> forwardGeocode(String address);

  /// Calculates the Great-Circle distance in meters between two coordinates.
  double distanceBetween(double lat1, double lng1, double lat2, double lng2);

  /// Formats distance in meters into a human-readable string (e.g. "450 m", "2.1 km").
  String formatDistance(double distanceInMeters, {bool imperial = false});
}

/// Production implementation of [GeocodingService] powered by the `geocoder_pro`
/// package utilizing OpenStreetMap (Nominatim) with built-in in-memory caching.
class GeocoderProService implements GeocodingService {
  final BaseGeocoder _geocoder;

  /// In-memory cache keyed by 4-decimal precision coordinates (~11m bucket).
  /// Prevents duplicate Nominatim queries when stationary while keeping pin drops accurate.
  final Map<String, String> _reverseCache = <String, String>{};

  /// User-Agent required by OpenStreetMap Nominatim usage policy.
  static const String defaultUserAgent =
      'PawsAndFound-App/1.0.0 (contact@pawsandfound.com; https://github.com/paws-and-found)';

  GeocoderProService({
    BaseGeocoder? geocoder,
    http.Client? httpClient,
  }) : _geocoder = geocoder ??
            NominatimGeocoder(
              userAgent: defaultUserAgent,
              client: httpClient,
              timeout: const Duration(seconds: 10),
            );

  /// Generates a coordinate cache key bucketed to ~11m resolution (4 decimal places).
  String _toCacheKey(double lat, double lng) =>
      '${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}';

  @override
  Future<String?> reverseGeocode(double lat, double lng) async {
    final cacheKey = _toCacheKey(lat, lng);
    if (_reverseCache.containsKey(cacheKey)) {
      return _reverseCache[cacheKey];
    }

    try {
      final GeoData? data = await _geocoder.getDataFromCoordinates(
        latitude: lat,
        longitude: lng,
      );

      if (data == null) return null;

      final formatted = formatConciseAddress(data);
      if (formatted.isNotEmpty) {
        _reverseCache[cacheKey] = formatted;
        return formatted;
      }
      return null;
    } catch (e) {
      debugPrint('[GeocoderProService] reverseGeocode failed for ($lat, $lng): $e');
      return null;
    }
  }

  @override
  Future<GeoCoordinates?> forwardGeocode(String address) async {
    final query = address.trim();
    if (query.isEmpty) return null;

    try {
      final GeoData? data = await _geocoder.getDataFromAddress(query);
      if (data == null) return null;
      return data.coordinates;
    } catch (e) {
      debugPrint('[GeocoderProService] forwardGeocode failed for "$address": $e');
      return null;
    }
  }

  @override
  double distanceBetween(double lat1, double lng1, double lat2, double lng2) {
    return GeoUtils.distanceBetween(lat1, lng1, lat2, lng2);
  }

  @override
  String formatDistance(double distanceInMeters, {bool imperial = false}) {
    return GeoUtils.formatDistance(distanceInMeters, imperial: imperial);
  }

  /// Extracts a clean, concise location tag suitable for mobile feed cards and headers.
  ///
  /// Intelligently checks landmarks, streets, and sublocalities before falling back to city.
  /// Examples:
  /// - "Cebu I.T. Park, Kasambagan" (commercial landmark + neighborhood)
  /// - "Salinas Drive, Lahug" (street + neighborhood)
  /// - "Kasambagan, Cebu City" (neighborhood + city)
  static String formatConciseAddress(GeoData data) {
    final rawAddress = (data.raw['address'] as Map<String, dynamic>?) ?? {};

    // 1. High-accuracy landmark / commercial hub / amenity
    final poi = (rawAddress['commercial'] as String?)?.trim() ??
        (rawAddress['amenity'] as String?)?.trim() ??
        (rawAddress['building'] as String?)?.trim() ??
        (rawAddress['leisure'] as String?)?.trim() ??
        (rawAddress['tourism'] as String?)?.trim() ??
        '';

    // 2. Street or thoroughfare
    final street = data.street.trim().isNotEmpty
        ? data.street.trim()
        : (rawAddress['road'] as String?)?.trim() ??
            (rawAddress['pedestrian'] as String?)?.trim() ??
            '';

    // 3. Sublocality / Barangay / Neighborhood
    final sub = data.subLocality.trim().isNotEmpty
        ? data.subLocality.trim()
        : (rawAddress['suburb'] as String?)?.trim() ??
            (rawAddress['neighbourhood'] as String?)?.trim() ??
            (rawAddress['village'] as String?)?.trim() ??
            (rawAddress['quarter'] as String?)?.trim() ??
            '';

    // 4. City / Municipality
    final city = data.city.trim().isNotEmpty
        ? data.city.trim()
        : (rawAddress['city'] as String?)?.trim() ??
            (rawAddress['town'] as String?)?.trim() ??
            (rawAddress['municipality'] as String?)?.trim() ??
            '';

    final state = data.state.trim().isNotEmpty
        ? data.state.trim()
        : (rawAddress['state'] as String?)?.trim() ??
            (rawAddress['province'] as String?)?.trim() ??
            '';

    // Priority 1: Landmark/POI + Sublocality or City
    if (poi.isNotEmpty) {
      if (sub.isNotEmpty && poi.toLowerCase() != sub.toLowerCase()) {
        return '$poi, $sub';
      } else if (city.isNotEmpty && poi.toLowerCase() != city.toLowerCase()) {
        return '$poi, $city';
      }
      return poi;
    }

    // Priority 2: Street + Sublocality (e.g. "V. Padriga Street, Kasambagan")
    if (street.isNotEmpty && sub.isNotEmpty && street.toLowerCase() != sub.toLowerCase()) {
      return '$street, $sub';
    }

    // Priority 3: Street + City (e.g. "Salinas Drive, Cebu City")
    if (street.isNotEmpty && city.isNotEmpty && street.toLowerCase() != city.toLowerCase()) {
      return '$street, $city';
    }

    // Priority 4: Sublocality + City (e.g. "Kasambagan, Cebu City")
    if (sub.isNotEmpty && city.isNotEmpty && sub.toLowerCase() != city.toLowerCase()) {
      return '$sub, $city';
    }

    // Priority 5: Fallback to first two segments of formattedAddress
    if (data.formattedAddress.isNotEmpty) {
      final segments = data.formattedAddress
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      if (segments.length >= 2) {
        return '${segments[0]}, ${segments[1]}';
      } else if (segments.isNotEmpty) {
        return segments.first;
      }
    }

    // Priority 6: City + State or single names
    if (city.isNotEmpty) {
      if (state.isNotEmpty && state.toLowerCase() != city.toLowerCase()) {
        return '$city, $state';
      }
      return city;
    }

    if (sub.isNotEmpty) return sub;
    if (state.isNotEmpty) return state;
    if (data.country.isNotEmpty) return data.country;

    return '';
  }
}
