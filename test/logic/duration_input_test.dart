import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/logic/duration_input.dart';

void main() {
  group('a bare number', () {
    test('under fifteen reads as hours', () {
      expect(parseDuration('3'), 180);
      expect(parseDuration('1'), 60);
      expect(parseDuration('14'), 14 * 60);
    });

    test('from fifteen up reads as minutes', () {
      expect(parseDuration('40'), 40);
      expect(parseDuration('15'), 15);
      expect(parseDuration('90'), 90);
    });

    test('zero is nothing at all', () {
      expect(parseDuration('0'), 0);
    });
  });

  group('fractions', () {
    test('a decimal is always hours — nobody logs 3.5 minutes', () {
      expect(parseDuration('3.5'), 210);
      expect(parseDuration('0.5'), 30);
      expect(parseDuration('1.25'), 75);
    });

    test('a comma works like a dot, as a Dutch keyboard produces', () {
      expect(parseDuration('3,5'), 210);
    });
  });

  group('the clock form', () {
    test('reads hours and minutes', () {
      expect(parseDuration('3:15'), 195);
      expect(parseDuration('0:45'), 45);
      expect(parseDuration('12:00'), 720);
    });

    test('single-digit minutes work', () {
      expect(parseDuration('1:5'), 65);
    });

    test('minutes past 59 are not a time', () {
      expect(parseDuration('1:75'), isNull);
    });
  });

  group('an explicit unit always wins over the guess', () {
    test('hours', () {
      expect(parseDuration('2h'), 120);
      expect(parseDuration('2 hours'), 120);
      expect(parseDuration('1.5h'), 90);
    });

    test('minutes, including values that would otherwise read as hours', () {
      expect(parseDuration('90m'), 90);
      expect(parseDuration('3 min'), 3, reason: '3 alone would be 3 hours');
      expect(parseDuration('45 minutes'), 45);
    });
  });

  test('whitespace and case do not matter', () {
    expect(parseDuration('  2H  '), 120);
  });

  group('nonsense logs nothing rather than something wrong', () {
    test('empty and rubbish', () {
      expect(parseDuration(''), isNull);
      expect(parseDuration('   '), isNull);
      expect(parseDuration('soon'), isNull);
      expect(parseDuration('3 apples'), isNull);
    });

    test('negatives', () {
      expect(parseDuration('-2'), isNull);
    });
  });
}
