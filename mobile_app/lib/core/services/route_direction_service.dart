import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Result of a route direction lookup between two coordinates.
class RouteDirectionResult {
  final List<LatLng> points;
  final double distanceMeters;
  final double? durationSeconds;
  final bool isFallbackStraightLine;

  const RouteDirectionResult({
    required this.points,
    required this.distanceMeters,
    this.durationSeconds,
    this.isFallbackStraightLine = false,
  });

  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  String? get formattedDuration {
    if (durationSeconds == null) return null;
    final mins = (durationSeconds! / 60).round();
    if (mins < 1) return '< 1 min';
    if (mins < 60) return '$mins min';
    final hrs = mins ~/ 60;
    final rem = mins % 60;
    return rem > 0 ? '${hrs}h ${rem}m' : '${hrs}h';
  }
}

/// Fetches street-level direction polylines via OSRM with a straight-line fallback.
class RouteDirectionService {
  const RouteDirectionService();

  Future<RouteDirectionResult> getDirections({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final routes = decoded['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final first = routes.first as Map<String, dynamic>;
          final geometry = first['geometry'] as Map<String, dynamic>?;
          final coords = geometry?['coordinates'] as List?;
          if (coords != null && coords.isNotEmpty) {
            final points = coords
                .map((c) {
                  final pair = c as List;
                  return LatLng(
                    (pair[1] as num).toDouble(),
                    (pair[0] as num).toDouble(),
                  );
                })
                .toList();

            final dist = (first['distance'] as num?)?.toDouble() ??
                const Distance().as(LengthUnit.Meter, origin, destination);
            final dur = (first['duration'] as num?)?.toDouble();

            return RouteDirectionResult(
              points: points,
              distanceMeters: dist,
              durationSeconds: dur,
              isFallbackStraightLine: false,
            );
          }
        }
      }
    } catch (_) {
      // Fall through to direct straight-line suggestion
    }

    final fallbackDist = const Distance().as(LengthUnit.Meter, origin, destination);
    return RouteDirectionResult(
      points: [origin, destination],
      distanceMeters: fallbackDist,
      isFallbackStraightLine: true,
    );
  }
}
