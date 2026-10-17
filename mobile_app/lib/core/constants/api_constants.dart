import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  ApiConstants._();

  /// Resolves the base URL for the Django orchestrator backend.
  /// - Android Emulator accesses host localhost via 10.0.2.2.
  /// - iOS Simulator, Desktop, and Web access via 127.0.0.1.
  static String get baseUrl {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  static String get healthEndpoint => '$baseUrl/api/health/';
  static String analyzeReportEndpoint(String reportId) => '$baseUrl/api/reports/$reportId/analyze/';
  static String analyzePetEndpoint(String petId) => '$baseUrl/api/pets/$petId/analyze/';
  static String respondMatchEndpoint(String matchId) => '$baseUrl/api/matches/$matchId/respond/';
}
