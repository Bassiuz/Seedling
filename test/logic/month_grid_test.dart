import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/logic/month_grid.dart';

void main() {
  group('monthGrid', () {
    test('always fills six rows, so the sheet never changes height', () {
      expect(monthGrid('2026-02-10'), hasLength(42));
      expect(monthGrid('2026-08-10'), hasLength(42));
    });

    test('starts on Monday, with blanks before the first', () {
      // 1 July 2026 is a Wednesday.
      final july = monthGrid('2026-07-28');
      expect(july.take(2), [null, null]);
      expect(july[2], '2026-07-01');
    });

    test('a month starting on a Monday has no blanks in front', () {
      // 1 June 2026 is a Monday.
      expect(monthGrid('2026-06-15').first, '2026-06-01');
    });

    test('ends on the last of the month, then blanks', () {
      final july = monthGrid('2026-07-28');
      expect(july.whereType<String>().last, '2026-07-31');
      expect(july.whereType<String>(), hasLength(31));
    });

    test('February knows about leap years', () {
      expect(monthGrid('2028-02-01').whereType<String>(), hasLength(29));
      expect(monthGrid('2026-02-01').whereType<String>(), hasLength(28));
    });
  });

  group('addMonths', () {
    test('steps forward and back across a year boundary', () {
      expect(addMonths('2026-12-15', 1), '2027-01-15');
      expect(addMonths('2026-01-15', -1), '2025-12-15');
    });

    test('clamps rather than spilling into the next month', () {
      expect(addMonths('2026-01-31', 1), '2026-02-28');
      expect(addMonths('2026-03-31', -1), '2026-02-28');
    });
  });

  test('monthsBetween counts months, not days', () {
    expect(monthsBetween('2026-07-31', '2026-08-01'), 1);
    expect(monthsBetween('2026-07-01', '2026-07-31'), 0);
    expect(monthsBetween('2026-07-01', '2025-07-01'), -12);
  });
}
