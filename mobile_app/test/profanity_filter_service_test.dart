import 'package:flutter_test/flutter_test.dart';
import 'package:paws_and_found/core/services/profanity_filter_service.dart';

// NOTE: ProfanityFilterService.instance can now be constructed without Supabase
// being initialized, because _supabase is a lazy getter only accessed inside
// recordInfraction(). Tests that call hasProfanity/findProfanities are
// entirely Supabase-free.

void main() {
  // We access the static-only detection API directly — no Supabase needed.
  group('ProfanityFilterService — detection (no Supabase required)', () {
    test('Clean text passes without detection', () {
      expect(ProfanityFilterService.hasProfanity('I saw this dog near the park yesterday! Hope he finds home.'), isFalse);
      expect(ProfanityFilterService.hasProfanity('Please pass this message to your class.'), isFalse);
      expect(ProfanityFilterService.hasProfanity('Such a sweet kitten, very friendly.'), isFalse);
    });

    test('Detects English bad words', () {
      expect(ProfanityFilterService.hasProfanity('You are an asshole'), isTrue);
      expect(ProfanityFilterService.findProfanities('What a bitch'), contains('bitch'));
    });

    test('Detects Filipino (Tagalog) bad words', () {
      expect(ProfanityFilterService.hasProfanity('tangina mo naman'), isTrue);
      expect(ProfanityFilterService.findProfanities('putang ina'), contains('putang ina'));
      expect(ProfanityFilterService.hasProfanity('ang bobo mo'), isTrue);
    });

    test('Detects Bisaya (Cebuano) bad words', () {
      expect(ProfanityFilterService.hasProfanity('buang ka'), isTrue);
      expect(ProfanityFilterService.hasProfanity('yawa jud kaayo'), isTrue);
      expect(ProfanityFilterService.hasProfanity('amaw man diay ka'), isTrue);
      expect(ProfanityFilterService.hasProfanity('piste'), isTrue);
    });

    test('Detects bubu (newly added Bisaya/Filipino slang)', () {
      expect(ProfanityFilterService.hasProfanity('bubu'), isTrue);
      expect(ProfanityFilterService.findProfanities('bubu'), contains('bubu'));
      expect(ProfanityFilterService.hasProfanity('ang bubu niya'), isTrue);
    });

    test('Detects leetspeak substitutions', () {
      expect(ProfanityFilterService.hasProfanity('b0g0 man ka'), isTrue);
      expect(ProfanityFilterService.hasProfanity('y4w4 jud'), isTrue);
      expect(ProfanityFilterService.hasProfanity('g4g0'), isTrue);
    });

    test('Detects repeated character flooding', () {
      expect(ProfanityFilterService.hasProfanity('buuuuang kaayo'), isTrue);
      expect(ProfanityFilterService.hasProfanity('yaaaawa'), isTrue);
    });

    test('No false positive for safe words containing substrings', () {
      // 'ass' must NOT trigger inside 'pass', 'grass', 'compass'
      expect(ProfanityFilterService.hasProfanity('please pass the grass'), isFalse);
    });
  });
}
