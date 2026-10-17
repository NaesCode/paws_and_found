import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Contract for device GPS and location operations across features.
///
/// Multi-feature services reside in `lib/core/services/` per Clean Architecture rules.
abstract class LocationService {
  Future<bool> isLocationServiceEnabled();
  Future<LocationPermission> checkPermission();
  Future<LocationPermission> requestPermission();
  Future<Position?> getCurrentPosition();
  Stream<Position> getPositionStream({int distanceFilter = 15});
}

/// Production implementation of [LocationService] utilizing the [Geolocator] plugin.
///
/// Incorporates best practices:
/// 1. Pre-flight hardware checks via [isLocationServiceEnabled].
/// 2. Graceful permission request flow without crashing.
/// 3. High precision with [LocationAccuracy.high].
/// 4. Jitter suppression via a 15-meter [distanceFilter] to eliminate bouncing.
class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  @override
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      debugPrint('[LocationService] Failed to check hardware service: $e');
      return false;
    }
  }

  @override
  Future<LocationPermission> checkPermission() async {
    try {
      return await Geolocator.checkPermission();
    } catch (e) {
      debugPrint('[LocationService] Failed to check permission: $e');
      return LocationPermission.denied;
    }
  }

  @override
  Future<LocationPermission> requestPermission() async {
    try {
      return await Geolocator.requestPermission();
    } catch (e) {
      debugPrint('[LocationService] Failed to request permission: $e');
      return LocationPermission.denied;
    }
  }

  @override
  Future<Position?> getCurrentPosition() async {
    try {
      // 1. Verify device GPS hardware is turned on
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[LocationService] GPS hardware is disabled on this device.');
        return null;
      }

      // 2. Check & handle permissions
      LocationPermission permission = await checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('[LocationService] Location permissions were denied by user.');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('[LocationService] Location permissions are permanently denied.');
        return null;
      }

      // 3. Request high-accuracy position with a defensive timeout
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );
    } catch (e) {
      debugPrint('[LocationService] Error fetching current location: $e');
      return null;
    }
  }

  @override
  Stream<Position> getPositionStream({int distanceFilter = 15}) {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 15,
    );
    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }
}
