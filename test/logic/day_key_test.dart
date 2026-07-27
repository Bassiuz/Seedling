import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/logic/day_key.dart';

void main() {
  group('dayKeyOf', () {
    test('zero-pads single-digit month and day', () {
      expect(dayKeyOf(DateTime(2026, 3, 9)), '2026-03-09');
    });

    test('zero-pads month only', () {
      expect(dayKeyOf(DateTime(2026, 1, 23)), '2026-01-23');
    });

    test('zero-pads day only', () {
      expect(dayKeyOf(DateTime(2026, 11, 5)), '2026-11-05');
    });
  });

  group('roundtrip', () {
    test('dayKeyOf(dateOfKey(k)) == k', () {
      const key = '2026-07-23';
      expect(dayKeyOf(dateOfKey(key)), key);
    });
  });

  group('addDays', () {
    test('across a month boundary', () {
      expect(addDays('2026-07-31', 1), '2026-08-01');
    });

    test('across a year boundary', () {
      expect(addDays('2026-12-31', 1), '2027-01-01');
    });

    test('with a negative delta', () {
      expect(addDays('2026-08-01', -1), '2026-07-31');
    });

    test('across the Europe/Amsterdam DST spring-forward', () {
      expect(addDays('2026-03-29', 1), '2026-03-30');
    });
  });
}
