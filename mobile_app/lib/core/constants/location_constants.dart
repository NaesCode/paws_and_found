import 'package:latlong2/latlong.dart';

/// Centralized geographic and location constants for the Paws and Found mobile app.
///
/// Localized for Cebu Province / Metro Cebu, Philippines.
class LocationConstants {
  LocationConstants._();

  // ---------------------------------------------------------------------------
  // Default Map Coordinates (Cebu City Center / Fuente Osmeña / Capitol)
  // ---------------------------------------------------------------------------
  static const double defaultLatitude = 10.3157;
  static const double defaultLongitude = 123.8854;

  static const LatLng defaultLocation = LatLng(defaultLatitude, defaultLongitude);

  // ---------------------------------------------------------------------------
  // Default Labels
  // ---------------------------------------------------------------------------
  static const String defaultCityName = 'Cebu City';
  static const String defaultProvince = 'Cebu';
  static const String defaultAreaLabel = 'Cebu City, Cebu';
  static const String defaultFallbackNote = 'Hardware GPS unavailable (Default Cebu City)';

  // ---------------------------------------------------------------------------
  // Map Camera Zoom Defaults
  // ---------------------------------------------------------------------------
  static const double defaultMapZoom = 14.5;
  static const double pinPickerZoom = 15.0;
  static const double focusedPetZoom = 16.0;

  // ---------------------------------------------------------------------------
  // Metro Cebu Key Landmarks Coordinates (for mocks, fixtures, and clustering)
  // ---------------------------------------------------------------------------
  static const LatLng fuenteOsmena = LatLng(10.3117, 123.8924);
  static const LatLng cebuITPark = LatLng(10.3297, 123.9063);
  static const LatLng emallCebu = LatLng(10.2982, 123.8975);
  static const LatLng lawaanTalisay = LatLng(10.2578, 123.8208);
  static const LatLng baniladMandaue = LatLng(10.3396, 123.9115);
  static const LatLng guadalupeCebu = LatLng(10.3242, 123.8821);
  static const LatLng ayalaCenterCebu = LatLng(10.3173, 123.9058);

  // ---------------------------------------------------------------------------
  // Cebu Geographic Bounds (Covers Cebu Province & Metro Cebu)
  // ---------------------------------------------------------------------------
  static const double cebuMinLatitude = 9.4;
  static const double cebuMaxLatitude = 11.4;
  static const double cebuMinLongitude = 123.2;
  static const double cebuMaxLongitude = 124.5;

  /// Checks if given latitude and longitude coordinates fall within Cebu province.
  static bool isWithinCebu(double latitude, double longitude) {
    return latitude >= cebuMinLatitude &&
        latitude <= cebuMaxLatitude &&
        longitude >= cebuMinLongitude &&
        longitude <= cebuMaxLongitude;
  }
}
