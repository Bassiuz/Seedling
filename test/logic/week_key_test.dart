import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/logic/week_key.dart';

void main() {
  group('weekKeyOf', () {
    test('numbers a mid-year week the way the vault filenames do', () {
      // Monday 27 July 2026 sits in ISO week 31.
      expect(weekKeyOf('2026-07-27'), '2026-W31');
      expect(weekKeyOf('2026-08-02'), '2026-W31', reason: 'same week, Sunday');
      expect(weekKeyOf('2026-08-03'), '2026-W32', reason: 'next Monday');
    });

    test('zero-pads so keys sort chronologically as strings', () {
      expect(weekKeyOf('2026-01-05'), '2026-W02');
      expect(
        ['2026-W02', '2026-W10'].toList()..sort(),
        ['2026-W02', '2026-W10'],
      );
    });

    test('a week belongs to the year holding its Thursday', () {
      // 1 January 2026 is a Thursday, so that week is 2026-W01 …
      expect(weekKeyOf('2026-01-01'), '2026-W01');
      // … and the Monday before it belongs to the same week, not to 2025.
      expect(weekKeyOf('2025-12-29'), '2026-W01');
    });

    test('late December can belong to the next year', () {
      // 31 December 2025 is a Wednesday, in the week of Thursday 1 Jan 2026.
      expect(weekKeyOf('2025-12-31'), '2026-W01');
    });
  });

  group('week bounds', () {
    test('a week runs Monday to Sunday', () {
      expect(weekStartOf('2026-07-29'), '2026-07-27');
      expect(weekEndOf('2026-07-29'), '2026-08-02');
    });

    test('Monday is its own start and Sunday its own end', () {
      expect(weekStartOf('2026-07-27'), '2026-07-27');
      expect(weekEndOf('2026-08-02'), '2026-08-02');
    });

    test('the bounds survive a month boundary', () {
      expect(weekStartOf('2026-08-02'), '2026-07-27');
    });
  });

  group('when a review is offered', () {
    test('Sunday is the review day', () {
      expect(isReviewDay('2026-08-02'), isTrue);
      expect(isReviewDay('2026-07-27'), isFalse);
    });

    test('reviewing on Sunday writes the week that is ending', () {
      expect(reviewWeekFor('2026-08-02'), '2026-W31');
    });

    test('from Monday on you are looking back at the week before', () {
      expect(reviewWeekFor('2026-08-03'), '2026-W31');
      expect(reviewWeekFor('2026-08-05'), '2026-W31');
    });
  });
}
