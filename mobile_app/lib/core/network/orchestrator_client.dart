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
///
/// Features automatic fallback between Android Emulator (10.0.2.2), Physical Phone / adb reverse (127.0.0.1),
/// and Ngrok HTTPS tunnel, plus network error retry with exponential backoff.
class OrchestratorClient {
  final http.Client _httpClient;
  final Duration timeout;

  OrchestratorClient({
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 60),
  }) : _httpClient = httpClient ?? http.Client();

  String? get _authToken => Supabase.instance.client.auth.currentSession?.accessToken;

  Map<String, String> _buildHeaders([Map<String, String>? extra]) {
    final headers = {
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': '1',
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
    };
    if (extra != null) {
      headers.addAll(extra);
    }
    return headers;
  }

  Future<dynamic> get(String path, {Map<String, String>? headers}) async {
    if (path.startsWith('http')) {
      return _executeRequest((uri) => _httpClient.get(uri, headers: _buildHeaders(headers)), Uri.parse(path));
    }

    final candidates = ApiConstants.candidateBaseUrls;
    Exception? lastException;

    for (final base in candidates) {
      final uri = Uri.parse('$base$path');
      try {
        final result = await _executeRequest(
          (u) => _httpClient.get(u, headers: _buildHeaders(headers)),
          uri,
        );
        ApiConstants.cacheWorkingBaseUrl(base);
        return result;
      } on OrchestratorException catch (e) {
        if (e.statusCode == 0 || e.statusCode == 408) {
          lastException = e;
          continue; // Try next candidate (e.g. fallback from 10.0.2.2 to 127.0.0.1)
        }
        rethrow;
      }
    }

    throw lastException ?? const OrchestratorException(statusCode: 0, message: 'All backend host candidates unreachable');
  }

  Future<dynamic> post(String path, {Object? body, Map<String, String>? headers}) async {
    if (path.startsWith('http')) {
      return _executeRequest(
        (uri) => _httpClient.post(
          uri,
          headers: _buildHeaders(headers),
          body: body != null ? jsonEncode(body) : null,
        ),
        Uri.parse(path),
      );
    }

    final candidates = ApiConstants.candidateBaseUrls;
    Exception? lastException;

    for (final base in candidates) {
      final uri = Uri.parse('$base$path');
      try {
        final result = await _executeRequest(
          (u) => _httpClient.post(
            u,
            headers: _buildHeaders(headers),
            body: body != null ? jsonEncode(body) : null,
          ),
          uri,
        );
        ApiConstants.cacheWorkingBaseUrl(base);
        return result;
      } on OrchestratorException catch (e) {
        if (e.statusCode == 0 || e.statusCode == 408) {
          lastException = e;
          continue; // Try next candidate (e.g. fallback from 10.0.2.2 to 127.0.0.1)
        }
        rethrow;
      }
    }

    throw lastException ?? const OrchestratorException(statusCode: 0, message: 'All backend host candidates unreachable');
  }

  Future<dynamic> _executeRequest(Future<http.Response> Function(Uri) requestFn, Uri uri) async {
    int attempts = 0;
    const maxAttempts = 3;
    Duration delay = const Duration(milliseconds: 500);

    while (true) {
      attempts++;
      try {
        final response = await requestFn(uri).timeout(timeout);
        return _processResponse(response);
      } on SocketException catch (e) {
        if (attempts >= maxAttempts) {
          throw OrchestratorException(statusCode: 0, message: 'Network connection error: $e');
        }
        await Future.delayed(delay);
        delay *= 2;
      } on TimeoutException {
        if (attempts >= maxAttempts) {
          throw const OrchestratorException(statusCode: 408, message: 'Request to orchestrator timed out');
        }
        await Future.delayed(delay);
        delay *= 2;
      } on http.ClientException catch (e) {
        if (attempts >= maxAttempts) {
          throw OrchestratorException(statusCode: 0, message: 'HTTP client error: $e');
        }
        await Future.delayed(delay);
        delay *= 2;
      }
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
    }

    throw OrchestratorException(
      statusCode: response.statusCode,
      message: jsonBody is Map && jsonBody.containsKey('error')
          ? jsonBody['error'].toString()
          : 'Request failed with status: ${response.statusCode}',
      details: jsonBody,
    );
  }
}
