import 'dart:typed_data';
import 'package:geocoder_pro/geocoder_pro.dart';

class GeocoderProImpl {
  const GeocoderProImpl();

  Future<String> getAddressFromHexEWKB(String? hexStr) async {
    if (hexStr == null || hexStr.isEmpty || hexStr.toLowerCase() == 'null') {
      return "No location pinned";
    }

    try {
      // 1. Convert the Hex string into raw bytes
      final List<int> bytes = [];
      for (int i = 0; i < hexStr.length; i += 2) {
        bytes.add(int.parse(hexStr.substring(i, i + 2), radix: 16));
      }

      final Uint8List uint8list = Uint8List.fromList(bytes);
      final ByteData byteData = ByteData.sublistView(uint8list);

      // 2. Validate standard little-endian PostGIS point metadata 
      final int byteOrder = byteData.getUint8(0);
      if (byteOrder != 1) {
        print("PawsAndFound Debug: Expected little-endian encoding (1), got: $byteOrder");
        return "Invalid Location Format";
      }

      // 3. Extract Coordinates based on PostGIS EWKB geometry offsets
      double longitude = 0.0;
      double latitude = 0.0;

      // FIXED OFFSETS: Explicitly aligns byte markers to map X to Longitude and Y to Latitude
      if (uint8list.length >= 43) {
        // Common 43-byte format containing SRID data
        longitude = byteData.getFloat64(27, Endian.little);
        latitude = byteData.getFloat64(35, Endian.little);
      } else if (uint8list.length >= 25) {
        // Standard 25-byte pure WKB layout without SRID
        longitude = byteData.getFloat64(9, Endian.little);
        latitude = byteData.getFloat64(17, Endian.little);
      } else {
        print("PawsAndFound Debug: Unexpected hex byte length: ${uint8list.length}");
        return "Unknown Location Structure";
      }

      // PRINT TO CONSOLE: This will now display the authentic unswapped position values!
      print("PawsAndFound Debug Parsed Coords -> Lat: $latitude, Lng: $longitude");

      // Verify coordinate limits
      if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
        print("PawsAndFound Debug: Coordinates out of limits! Lat: $latitude, Lng: $longitude");
        return "Pinned Location (Coordinate Error)";
      }

      // 4. Pass the verified numbers down to geocoder_pro engine below
      return await getAddressFromCoords(latitude, longitude);
    } catch (e) {
      print("PawsAndFound Debug: Failed parsing geography hex format: $e");
      return "Pinned Location (Hex Parse Exception)";
    }
  }

  /// Step B: Reverse geocoding via the geocoder_pro Nominatim driver module
  Future<String> getAddressFromCoords(double? lat, double? lng) async {
    if (lat == null || lng == null || (lat == 0.0 && lng == 0.0)) {
      return "No location pinned";
    }

    try {
      final reverseData = await GeocoderPro.nominatim().getDataFromCoordinates(
        latitude: lat,
        longitude: lng,
      );

      if (reverseData != null) {
        final String city = reverseData.city ?? '';

        if (reverseData.formattedAddress != null && reverseData.formattedAddress!.isNotEmpty) {
          final String fullAddress = reverseData.formattedAddress!;
          if (city.isNotEmpty) {
            final String streetPart = fullAddress.split(',').first.trim();
            if (streetPart.toLowerCase() != city.toLowerCase()) {
              return "$streetPart, $city";
            }
            return city;
          }
          return fullAddress.split(',').take(2).join(',').trim();
        }
      }
    } catch (e) {
      print("PawsAndFound Debug: GeocoderPro request exception: $e");
    }

    return "Pinned Location (${lat.toStringAsFixed(3)}, ${lng.toStringAsFixed(3)})";
  }
}
