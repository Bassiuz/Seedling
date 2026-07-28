import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/logic/recent_emoji.dart';

void main() {
  group('promoteEmoji', () {
    test('a new one goes to the front', () {
      expect(promoteEmoji(['😄', '🤔'], '💻'), ['💻', '😄', '🤔']);
    });

    test('re-using one moves it to the front instead of duplicating it', () {
      expect(promoteEmoji(['😄', '🤔', '💻'], '💻'), ['💻', '😄', '🤔']);
    });

    test('the one already at the front stays there', () {
      expect(promoteEmoji(['💻', '😄'], '💻'), ['💻', '😄']);
    });

    test('only ten are kept, and it is the oldest that falls off', () {
      const full = [
        '😄', '🤔', '💻', '🚲', '🦴', '🎰', '⏲️', '😢', '🌱', '📚',
      ];
      final after = promoteEmoji(full, '🎯');

      expect(after, hasLength(recentEmojiLimit));
      expect(after.first, '🎯');
      expect(after.contains('📚'), isFalse, reason: 'the oldest fell off');
      expect(after.contains('😄'), isTrue);
    });

    test('starting from nothing gives a list of one', () {
      expect(promoteEmoji(const [], '😄'), ['😄']);
    });

    test('blank input leaves the list alone', () {
      expect(promoteEmoji(['😄'], '   '), ['😄']);
      expect(promoteEmoji(['😄'], ''), ['😄']);
    });

    test('the original list is not modified', () {
      final original = ['😄', '🤔'];
      promoteEmoji(original, '💻');

      expect(original, ['😄', '🤔']);
    });
  });

  group('firstEmoji', () {
    test('keeps a plain emoji', () {
      expect(firstEmoji('😄'), '😄');
    });

    test('a flag survives as one character', () {
      // Two code points, one grapheme cluster.
      expect(firstEmoji('🇳🇱'), '🇳🇱');
    });

    test('a skin tone stays attached', () {
      expect(firstEmoji('👍🏽'), '👍🏽');
    });

    test('only the first is kept when several are typed', () {
      expect(firstEmoji('😄🤔💻'), '😄');
    });

    test('surrounding spaces are ignored', () {
      expect(firstEmoji('  🎯  '), '🎯');
    });

    test('nothing usable gives null', () {
      expect(firstEmoji(''), isNull);
      expect(firstEmoji('   '), isNull);
    });

    test('a letter is accepted as written — some people use one', () {
      expect(firstEmoji('x'), 'x');
    });
  });
}
