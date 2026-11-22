import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Details of a violation check and any resultant account status escalation.
class UserViolationRecord {
  /// Cumulative count of recorded violations for the user.
  final int count;

  /// The resulting user account status ('Active', 'Warning', or 'Suspended').
  final String status;

  /// The prohibited word detected during this attempt.
  final String prohibitedWord;

  /// Whether this violation escalated the account to 'Warning'.
  final bool isWarning;

  /// Whether this violation escalated the account to 'Suspended'.
  final bool isSuspended;

  /// Whether an automated notification should be displayed/dispatched.
  final bool shouldNotify;

  const UserViolationRecord({
    required this.count,
    required this.status,
    required this.prohibitedWord,
    this.isWarning = false,
    this.isSuspended = false,
    this.shouldNotify = false,
  });
}

/// Service that enforces account status restrictions, tracks violation strikes,
/// and escalates user status (Active -> Warning -> Suspended) based on community policy.
///
/// Escalation Rules:
/// - 1–2 attempts: status remains 'Active'
/// - 3–4 attempts: status escalates to 'Warning'
/// - >= 5 attempts: status escalates to 'Suspended'
class UserRestrictionService {
  final SupabaseClient? _supabaseClient;
  static const String _prefPrefix = 'user_violations_';
  static final Map<String, int> _inMemoryViolations = {};

  const UserRestrictionService({SupabaseClient? supabaseClient})
      : _supabaseClient = supabaseClient;

  SupabaseClient? get _client {
    if (_supabaseClient != null) return _supabaseClient;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Retrieves the current violation count for [userId].
  Future<int> getViolationCount(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('$_prefPrefix$userId') ?? _inMemoryViolations[userId] ?? 0;
    } catch (_) {
      return _inMemoryViolations[userId] ?? 0;
    }
  }

  /// Records a violation for [userId] when prohibited language is submitted.
  Future<UserViolationRecord> recordViolation({
    required String userId,
    required String prohibitedWord,
  }) async {
    final currentCount = await getViolationCount(userId);
    final newCount = currentCount + 1;

    // Persist strike count locally
    _inMemoryViolations[userId] = newCount;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('$_prefPrefix$userId', newCount);
    } catch (_) {}

    String newStatus = 'Active';
    bool isWarning = false;
    bool isSuspended = false;
    bool shouldNotify = false;

    if (newCount >= 5) {
      newStatus = 'Suspended';
      isSuspended = true;
      shouldNotify = true;
      await _updateAccountStatus(
        userId,
        'Suspended',
        'Your account has been suspended due to repeated violations of community guidelines ($newCount violations recorded).',
      );
    } else if (newCount >= 3) {
      newStatus = 'Warning';
      isWarning = true;
      shouldNotify = true;
      await _updateAccountStatus(
        userId,
        'Warning',
        'Warning: Repeated use of prohibited language will lead to account suspension ($newCount violations recorded).',
      );
    }

    return UserViolationRecord(
      count: newCount,
      status: newStatus,
      prohibitedWord: prohibitedWord,
      isWarning: isWarning,
      isSuspended: isSuspended,
      shouldNotify: shouldNotify,
    );
  }

  /// Checks whether [userId] (or the currently authenticated user) is suspended.
  Future<bool> isUserSuspended([String? userId]) async {
    final status = await getUserStatus(userId);
    return status.toLowerCase().contains('suspend');
  }

  /// Checks the current account status for [userId] (or the logged-in user).
  Future<String> getUserStatus([String? userId]) async {
    final uid = userId ?? _client?.auth.currentUser?.id;
    if (uid == null) return 'Active';

    // 1. If local strikes reached suspension threshold, enforce immediately
    final localStrikes = await getViolationCount(uid);
    if (localStrikes >= 5) return 'Suspended';
    if (localStrikes >= 3) return 'Warning';

    // 2. Query Supabase profiles table if available
    try {
      final client = _client;
      if (client != null) {
        final res = await client
            .from('profiles')
            .select('status')
            .eq('id', uid)
            .maybeSingle();
        if (res != null && res['status'] != null) {
          return res['status'] as String;
        }
      }
    } catch (e) {
      debugPrint('[UserRestrictionService] Error fetching profile status: $e');
    }

    return 'Active';
  }

  /// Updates status in profiles and creates notification in Supabase.
  Future<void> _updateAccountStatus(String userId, String status, String notificationMessage) async {
    try {
      final client = _client;
      if (client != null) {
        await client
            .from('profiles')
            .update({'status': status})
            .eq('id', userId);

        await client.from('notifications').insert({
          'user_id': userId,
          'type': status.toLowerCase() == 'warning' ? 'warning' : 'suspension',
          'message': notificationMessage,
        });
      }
    } catch (e) {
      debugPrint('[UserRestrictionService] Error escalating user status: $e');
    }
  }

  /// Resets violation strikes for [userId] (used in testing and admin resets).
  Future<void> clearViolations(String userId) async {
    _inMemoryViolations.remove(userId);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_prefPrefix$userId');
    } catch (_) {}
  }
}
