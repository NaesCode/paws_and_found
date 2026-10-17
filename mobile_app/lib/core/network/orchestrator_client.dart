import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/api_constants.dart';

class OrchestratorException implements Exception {
  final int statusCode;
  final String message;
  final dynamic details;

  const OrchestratorException({
    required this.statusCode,
    required this.message,
    this.details,
  });

  @override
  String toString() => 'OrchestratorException($statusCode): $message';
}

/// HTTP client dedicated to communicating with the Django orchestrator micro-service.
/// Automatically attaches the current user's Supabase JWT access token.
class OrchestratorClient {
  final http.Client _httpClient;
  final Duration timeout;

  OrchestratorClient({
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 15),
  }) : _httpClient = httpClient ?? http.Client();

  String? get _authToken => Supabase.instance.client.auth.currentSession?.accessToken;

  Map<String, String> _buildHeaders([Map<String, String>? extra]) {
    final headers = {
      'Content-Type': 'application/json',
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
    };
    if (extra != null) {
      headers.addAll(extra);
    }
    return headers;
  }

  Future<dynamic> get(String path, {Map<String, String>? headers}) async {
    final uri = path.startsWith('http') ? Uri.parse(path) : Uri.parse('${ApiConstants.baseUrl}$path');
    try {
      final response = await _httpClient
          .get(uri, headers: _buildHeaders(headers))
          .timeout(timeout);
      return _processResponse(response);
    } on SocketException catch (e) {
      throw OrchestratorException(statusCode: 0, message: 'Network connection error: $e');
    } on TimeoutException {
      throw const OrchestratorException(statusCode: 408, message: 'Request to orchestrator timed out');
    }
  }

  Future<dynamic> post(String path, {Object? body, Map<String, String>? headers}) async {
    final uri = path.startsWith('http') ? Uri.parse(path) : Uri.parse('${ApiConstants.baseUrl}$path');
    try {
      final response = await _httpClient
          .post(
            uri,
            headers: _buildHeaders(headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout);
      return _processResponse(response);
    } on SocketException catch (e) {
      throw OrchestratorException(statusCode: 0, message: 'Network connection error: $e');
    } on TimeoutException {
      throw const OrchestratorException(statusCode: 408, message: 'Request to orchestrator timed out');
    }
  }

  dynamic _processResponse(http.Response response) {
    dynamic jsonBody;
    if (response.body.isNotEmpty) {
      try {
        jsonBody = jsonDecode(response.body);
      } catch (_) {
        jsonBody = response.body;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonBody;
    } else {
      String message = 'Orchestrator returned ${response.statusCode}';
      if (jsonBody is Map<String, dynamic>) {
        message = jsonBody['detail'] ?? jsonBody['message'] ?? message;
      }
      throw OrchestratorException(
        statusCode: response.statusCode,
        message: message,
        details: jsonBody,
      );
    }
  }
}

