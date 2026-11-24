import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/api_constants.dart';

/// Render backend availability states.
enum BackendStatus {
  /// No ping has been attempted yet (initial state).
  unknown,

  /// Backend responded with HTTP 200 — AI is live and warm, user is authenticated.
  online,

  /// Backend is reachable but returned an unexpected status code.
  degraded,

  /// Backend is unreachable / timed out — Render may be cold-starting.
  offline,

  /// A ping is currently in-flight.
  checking,
}

/// Singleton service that keeps the Render backend warm by sending a lightweight
/// GET `/api/health/` ping (with the user's Supabase JWT) every [pingInterval]
/// (default 15 minutes).
///
/// The endpoint requires authentication; sending the JWT ensures the backend
/// responds with 200 OK for logged-in users while remaining protected.
/// A 401 response means the server is running but the user is not yet signed in.
///
/// • Exposes a [ValueNotifier<BackendStatus>] so any widget can listen reactively.
/// • Fires an **immediate** ping on first call to [initialize] so the camera page
///   can show the correct status right away without waiting 15 minutes.
/// • The periodic timer is cancelled automatically via [dispose].
///
/// Usage:
/// ```dart
/// // In main.dart (once, after Supabase.initialize):
/// BackendStatusService.instance.initialize();
///
/// // In a widget:
/// ValueListenableBuilder<BackendStatus>(
///   valueListenable: BackendStatusService.instance.status,
///   builder: (_, status, __) => BackendStatusChip(status: status),
/// );
/// ```
class BackendStatusService {
  BackendStatusService._();
  static final BackendStatusService instance = BackendStatusService._();

  static const Duration pingInterval = Duration(minutes: 15);
  static const Duration _pingTimeout = Duration(seconds: 10);

  final ValueNotifier<BackendStatus> status =
      ValueNotifier(BackendStatus.unknown);

  Timer? _timer;
  bool _initialized = false;
  http.Client _client = http.Client();

  @visibleForTesting
  set httpClient(http.Client client) => _client = client;

  String? get _authToken {
    try {
      return Supabase.instance.client.auth.currentSession?.accessToken;
    } catch (_) {
      return null;
    }
  }

  /// Starts the keep-alive ping loop.  Safe to call multiple times — subsequent
  /// calls are no-ops unless [force] is `true`.
  void initialize({bool force = false}) {
    if (_initialized && !force) return;
    _initialized = true;

    // Immediate first ping
    unawaited(_ping());

    // Recurring ping every [pingInterval]
    _timer?.cancel();
    _timer = Timer.periodic(pingInterval, (_) => unawaited(_ping()));
  }

  /// Sends a single lightweight ping to the backend health endpoint and updates
  /// [status].  Returns the resolved [BackendStatus].
  Future<BackendStatus> ping() async {
    return _ping();
  }

  Future<BackendStatus> _ping() async {
    status.value = BackendStatus.checking;
    try {
      final headers = <String, String>{};
      final token = _authToken;
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await _client
          .get(Uri.parse(ApiConstants.healthEndpoint), headers: headers)
          .timeout(_pingTimeout);

      if (response.statusCode == 200) {
        // Authenticated and server is healthy
        status.value = BackendStatus.online;
        debugPrint('[BackendStatusService] ✓ Backend online (200)');
      } else if (response.statusCode == 401) {
        // Server is running but user is not logged in yet — treat as online
        // since the container is warm; the AI will work once the user authenticates.
        status.value = BackendStatus.online;
        debugPrint('[BackendStatusService] ✓ Backend online (401 — not signed in yet)');
      } else {
        status.value = BackendStatus.degraded;
        debugPrint('[BackendStatusService] ⚠ Backend degraded (${response.statusCode})');
      }
    } catch (e) {
      status.value = BackendStatus.offline;
      debugPrint('[BackendStatusService] ✗ Backend offline ($e)');
    }
    return status.value;
  }

  /// Cancels the periodic timer.  Call from your top-level widget's dispose if
  /// you ever want to stop the pinger (usually not needed for app lifetime).
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
