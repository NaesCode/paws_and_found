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
/// Supports English, Tagalog, and Cebuano/Bisaya prohibited terms with word-boundary
/// matching to prevent false positives on benign words.
class ContentModerationService {
  const ContentModerationService();

  /// Curated list of prohibited terms across Cebuano, Tagalog, and English.
  static const List<String> _prohibitedTerms = [
    // Cebuano / Bisaya
    'buang',
    'buanga',
    'yawa',
    'yawaa',
    'atay',
    'ataya',
    'piste',
    'pisting',
    'pesteng',
    'bilat',
    'oten',
    'kayat',
    'lubot',
    'hudas',

    // Tagalog / Filipino
    'gago',
    'gaga',
    'tanga',
    'puta',
    'tangina',
    'putangina',
    'ulol',
    'tarantado',
    'kupal',
    'inutil',
    'pakshet',
    'leche',
    'hindot',
    'punyeta',

    // English
    'fuck',
    'fucking',
    'fucker',
    'shit',
    'bullshit',
    'bitch',
    'asshole',
    'bastard',
    'cunt',
    'dick',
    'pussy',
    'nigger',
    'nigga',
    'whore',
    'slut',
    'faggot',
  ];

  /// Scans the provided [text] for prohibited vocabulary.
  ///
  /// Returns a [ModerationCheckResult] containing approval status and the
  /// detected word if a violation is found.
  ModerationCheckResult checkContent(String? text) {
    if (text == null || text.trim().isEmpty) {
      return const ModerationCheckResult(isClean: true);
    }

    final sanitized = text.toLowerCase();

    for (final term in _prohibitedTerms) {
      // Use regex with word boundaries (\b) or punctuation boundaries to avoid
      // false positives (e.g. 'assistant', 'assessment', 'classic').
      final pattern = RegExp(r'(^|\W)' + RegExp.escape(term) + r'($|\W)', caseSensitive: false);
      if (pattern.hasMatch(sanitized)) {
        return ModerationCheckResult(
          isClean: false,
          detectedWord: term,
        );
      }
    }

    return const ModerationCheckResult(isClean: true);
  }
}
