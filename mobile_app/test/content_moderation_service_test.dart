import 'package:flutter_test/flutter_test.dart';
import 'package:paws_and_found/core/services/content_moderation_service.dart';

void main() {
  late ContentModerationService service;

  setUp(() {
    service = const ContentModerationService();
  });

  group('ContentModerationService Tests', () {
    test('approves clean, encouraging community messages', () {
      const messages = [
        'I saw this brown dog near Lahug market around 2 PM!',
        'Hoping the pet finds its home soon. Stay safe!',
        'Cute cat, hope it is reunited with family.',
        'Sharing this to my friends in Cebu City.',
      ];

      for (final msg in messages) {
        final result = service.checkContent(msg);
        expect(result.isClean, isTrue, reason: 'Failed for clean message: $msg');
        expect(result.isBlocked, isFalse);
        expect(result.detectedWord, isNull);
      }
    });

    test('detects Cebuano prohibited terms like "buang" and "yawa"', () {
      final res1 = service.checkContent('Grabe ka buang ani oy');
      expect(res1.isBlocked, isTrue);
      expect(res1.detectedWord, 'buang');

      final res2 = service.checkContent('yawa ngano ingon ana man');
      expect(res2.isBlocked, isTrue);
      expect(res2.detectedWord, 'yawa');

      final res3 = service.checkContent('piste kaayo!');
      expect(res3.isBlocked, isTrue);
      expect(res3.detectedWord, 'piste');
    });

    test('detects Tagalog prohibited terms', () {
      final res1 = service.checkContent('Ang gago mo naman');
      expect(res1.isBlocked, isTrue);
      expect(res1.detectedWord, 'gago');

      final res2 = service.checkContent('tanga talaga neto');
      expect(res2.isBlocked, isTrue);
      expect(res2.detectedWord, 'tanga');
    });

    test('detects English prohibited terms', () {
      final res1 = service.checkContent('What the fuck is this');
      expect(res1.isBlocked, isTrue);
      expect(res1.detectedWord, 'fuck');

      final res2 = service.checkContent('this is total bullshit');
      expect(res2.isBlocked, isTrue);
      expect(res2.detectedWord, 'bullshit');
    });

    test('does not false-positive on benign words containing substrings', () {
      const benign = [
        'assistant manager at the rescue shelter',
        'classic brown tabby kitten',
        'the assessment of the vet was good',
        'class pet',
        'passenger seat',
      ];

      for (final b in benign) {
        final result = service.checkContent(b);
        expect(result.isClean, isTrue, reason: 'False positive triggered on: $b');
      }
    });

    test('handles empty or null text safely', () {
      expect(service.checkContent(null).isClean, isTrue);
      expect(service.checkContent('').isClean, isTrue);
      expect(service.checkContent('   ').isClean, isTrue);
    });
  });
}
