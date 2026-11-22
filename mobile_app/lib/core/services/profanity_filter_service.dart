import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/profanity_dictionary.dart';

/// Result of an infraction recorded against a user's account for profanity.
class ProfanityInfractionResult {
  final int infractionCount;
  final String status;
  final bool isSuspended;
  final bool isWarned;
  final String message;

  const ProfanityInfractionResult({
    required this.infractionCount,
    required this.status,
    required this.isSuspended,
    required this.isWarned,
    required this.message,
  });

  factory ProfanityInfractionResult.fromMap(Map<String, dynamic> map) {
    final status = (map['status'] as String? ?? 'Active');
    final count = (map['infraction_count'] as num?)?.toInt() ?? 1;
    final isSuspended = status.toLowerCase() == 'suspended' || status.toLowerCase() == 'suspension';
    final isWarned = status.toLowerCase() == 'warning';

    String message;
    if (isSuspended) {
      message = 'Your account has been suspended due to repeated prohibited language violations in community discussions.';
    } else if (isWarned) {
      message = 'Warning: Continued use of prohibited language will result in account suspension ($count violations recorded).';
    } else {
      message = 'Please keep community discussions respectful. Offensive language is not allowed ($count/5 warnings).';
    }

    return ProfanityInfractionResult(
      infractionCount: count,
      status: status,
      isSuspended: isSuspended,
      isWarned: isWarned,
      message: message,
    );
  }
}

/// Singleton service responsible for detecting prohibited/offensive words
/// across English, Filipino (Tagalog), and Bisaya (Cebuano).
///
/// Adheres strictly to Clean Architecture (lib/core/services/).
class ProfanityFilterService {
  ProfanityFilterService._();
  static final ProfanityFilterService instance = ProfanityFilterService._();

  /// Lazy getter — only accessed when recording an infraction, so the service
  /// can be instantiated (and its pure-Dart detection methods used) even before
  /// Supabase.initialize() completes (e.g. in unit tests or early app startup).
  SupabaseClient get _supabase => Supabase.instance.client;

  /// Cached multi-word phrases and single words for optimized matching.
  static final List<String> _multiWordPhrases = ProfanityDictionary.words
      .where((w) => w.contains(' '))
      .toList();

  static final Set<String> _singleWords = ProfanityDictionary.words
      .where((w) => !w.contains(' '))
      .toSet();

  /// Normalizes common leetspeak substitutions (e.g. 'g4g0' -> 'gago').
  static String normalizeText(String input) {
    var text = input.toLowerCase();

    // Map common digit/symbol substitutions
    text = text
        .replaceAll('@', 'a')
        .replaceAll('4', 'a')
        .replaceAll('0', 'o')
        .replaceAll('1', 'i')
        .replaceAll('!', 'i')
        .replaceAll('3', 'e')
        .replaceAll(r'$', 's')
        .replaceAll('5', 's')
        .replaceAll('7', 't');

    return text;
  }

  /// Collapses excessive repeated characters (e.g., 'buuuuang' -> 'buang', 'gaaaago' -> 'gago').
  static String collapseRepeatedChars(String text) {
    return text.replaceAllMapped(RegExp(r'(.)\1{2,}'), (match) => match.group(1)!);
  }

  /// Checks if [text] contains any prohibited words or phrases.
  ///
  /// **Static** — pure Dart, no Supabase required. Safe to call in tests
  /// and before Supabase.initialize() completes.
  static bool hasProfanity(String text) {
    return findProfanities(text).isNotEmpty;
  }

  /// Returns all detected prohibited words or phrases from [text].
  ///
  /// **Static** — pure Dart, no Supabase required. Safe to call in tests
  /// and before Supabase.initialize() completes.
  static List<String> findProfanities(String text) {
    if (text.trim().isEmpty) return const [];

    final detected = <String>{};
    final rawLower = text.toLowerCase();
    final normalized = normalizeText(rawLower);
    final collapsed = collapseRepeatedChars(normalized);

    // 1. Check multi-word phrases (e.g. 'putang ina', '2 girls 1 cup')
    for (final phrase in _multiWordPhrases) {
      if (rawLower.contains(phrase) || normalized.contains(phrase) || collapsed.contains(phrase)) {
        detected.add(phrase);
      }
    }

    // 2. Check single words using word boundaries to avoid false positives
    //    (e.g. 'ass' must NOT match inside 'pass', 'grass', 'compass').
    final wordRegex = RegExp(r'[a-zA-Z0-9]+');
    final matches = wordRegex.allMatches(rawLower);

    for (final match in matches) {
      final rawWord = match.group(0)!;
      final normWord = normalizeText(rawWord);
      final collWord = collapseRepeatedChars(normWord);

      if (_singleWords.contains(rawWord)) {
        detected.add(rawWord);
      } else if (_singleWords.contains(normWord)) {
        detected.add(rawWord);
      } else if (_singleWords.contains(collWord)) {
        detected.add(rawWord);
      }
    }

    return detected.toList();
  }

  /// Reports a profanity violation to Supabase RPC, incrementing the user's
  /// infraction count and applying warning or suspension if behavior limits are reached.
  Future<ProfanityInfractionResult> recordInfraction(List<String> detectedWords) async {
    try {
      final res = await _supabase.rpc(
        'record_profanity_infraction',
        params: {
          'p_detected_words': detectedWords.join(', '),
        },
      );

      if (res is Map<String, dynamic>) {
        return ProfanityInfractionResult.fromMap(res);
      }
    } catch (e) {
      debugPrint('[ProfanityFilterService] Error recording infraction: $e');
    }

    // Fallback if offline or RPC fails
    return const ProfanityInfractionResult(
      infractionCount: 1,
      status: 'Active',
      isSuspended: false,
      isWarned: false,
      message: 'Please keep community discussions respectful. Offensive language is not allowed.',
    );
  }
}
