import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  ApiConstants._();

  static const String emulatorHost = '10.0.2.2';
  static const String localhost = '127.0.0.1';
  static const int port = 8000;

  static String? _resolvedBaseUrl;

  /// Returns the active base URL for the Django orchestrator backend.
  static String get baseUrl {
    if (_resolvedBaseUrl != null) return _resolvedBaseUrl!;

    const override = String.fromEnvironment('BACKEND_HOST');
    if (override.isNotEmpty) {
      return 'http://$override:$port';
    }

    // Default: Android Emulator uses 10.0.2.2; everything else uses 127.0.0.1
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://$emulatorHost:$port';
    }
    return 'http://$localhost:$port';
  }

  /// Alternate candidate URLs to attempt if the primary URL is unreachable
  /// (e.g. physical phone with adb reverse vs. emulator).
  static List<String> get candidateBaseUrls {
    const override = String.fromEnvironment('BACKEND_HOST');
    if (override.isNotEmpty) {
      return ['http://$override:$port'];
    }

    if (!kIsWeb && Platform.isAndroid) {
      return [
        'http://$emulatorHost:$port', // Android Emulator default
        'http://$localhost:$port',    // Physical Phone with adb reverse
      ];
    }
    return ['http://$localhost:$port'];
  }

  /// Caches the working URL so subsequent calls connect instantly without probing.
  static void cacheWorkingBaseUrl(String url) {
    _resolvedBaseUrl = url;
  }

  static String get healthEndpoint => '$baseUrl/api/health/';
  static String analyzeReportEndpoint(String reportId) => '$baseUrl/api/reports/$reportId/analyze/';
  static String analyzePetEndpoint(String petId) => '$baseUrl/api/pets/$petId/analyze/';
  static String respondMatchEndpoint(String matchId) => '$baseUrl/api/matches/$matchId/respond/';
}

