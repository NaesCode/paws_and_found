import 'package:paws_and_found/core/constants/profanity_dictionary.dart';
import 'package:paws_and_found/core/services/profanity_filter_service.dart';

/// Result of a content moderation scan.
class ModerationCheckResult {
  /// Whether the text passed content moderation guidelines without violation.
  final bool isClean;

  /// The first prohibited term detected in the text, if any.
  final String? detectedWord;

  const ModerationCheckResult({
    required this.isClean,
    this.detectedWord,
  });

  /// Convenience getter indicating if the content was flagged/blocked.
  bool get isBlocked => !isClean;
}

/// Service responsible for scanning user-generated text (comments, messages, descriptions)
/// against community safety guidelines and prohibited profanity lists.
///
/// Backed by [ProfanityFilterService] and [ProfanityDictionary] with support for
/// English, Tagalog, and Cebuano/Bisaya prohibited terms, leetspeak normalization,
/// repeated-character collapsing, and word-boundary matching to prevent false positives.
class ContentModerationService {
  const ContentModerationService();

  /// Prohibited terms set backed by the centralized [ProfanityDictionary].
  static Set<String> get prohibitedTerms => ProfanityDictionary.words;

  /// Scans the provided [text] for prohibited vocabulary.
  ///
  /// Returns a [ModerationCheckResult] containing approval status and the
  /// detected word if a violation is found.
  ModerationCheckResult checkContent(String? text) {
    if (text == null || text.trim().isEmpty) {
      return const ModerationCheckResult(isClean: true);
    }

    final detected = ProfanityFilterService.findProfanities(text);
    if (detected.isNotEmpty) {
      return ModerationCheckResult(
        isClean: false,
        detectedWord: detected.first,
      );
    }

    return const ModerationCheckResult(isClean: true);
  }
}
