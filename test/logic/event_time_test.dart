import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/logic/event_time.dart';

void main() {
  group('localEventTime', () {
    test('a UTC instant is shown in local wall-clock time', () {
      // The bug this replaces showed a 13:30 Amsterdam appointment as 11:30,
      // i.e. the UTC digits. Asserting against the machine's own offset keeps
      // this honest wherever it runs.
      final instant = DateTime.utc(2026, 7, 28, 11, 30);
      final local = instant.toLocal();

      final result = localEventTime(instant, allDay: false);

      expect(result.time, clockOf(local));
      expect(result.dayKey,
          '${local.year}-${local.month.toString().padLeft(2, '0')}-'
          '${local.day.toString().padLeft(2, '0')}');
    });

    test('a local DateTime is left where it already is', () {
      final start = DateTime(2026, 7, 28, 13, 30);

      final result = localEventTime(start, allDay: false);

      expect(result.time, '13:30');
      expect(result.dayKey, '2026-07-28');
    });

    test('an event late in the evening keeps its own day', () {
      final start = DateTime(2026, 7, 28, 23, 45);

      expect(localEventTime(start, allDay: false).dayKey, '2026-07-28');
      expect(localEventTime(start, allDay: false).time, '23:45');
    });

    test('an all-day event keeps its date and has no time', () {
      // Midnight UTC is the awkward case: converting it can land on the 27th.
      final start = DateTime.utc(2026, 7, 28);

      final result = localEventTime(start, allDay: true);

      expect(result.dayKey, '2026-07-28');
      expect(result.time, isNull);
    });

    test('midnight is padded rather than shortened', () {
      expect(localEventTime(DateTime(2026, 7, 28, 0, 5), allDay: false).time,
          '00:05');
    });
  });

  group('isOverdue', () {
    const today = '2026-07-28';

    test('a time already gone by today is overdue', () {
      expect(
        isOverdue(day: today, time: '09:00', today: today, now: '14:00'),
        isTrue,
      );
    });

    test('a time still to come today is not', () {
      expect(
        isOverdue(day: today, time: '17:00', today: today, now: '14:00'),
        isFalse,
      );
    });

    test('the current minute is not yet late', () {
      expect(
        isOverdue(day: today, time: '14:00', today: today, now: '14:00'),
        isFalse,
      );
    });

    test('yesterday is history, not something to chase', () {
      expect(
        isOverdue(day: '2026-07-27', time: '09:00', today: today, now: '14:00'),
        isFalse,
      );
    });

    test('tomorrow has not arrived', () {
      expect(
        isOverdue(day: '2026-07-29', time: '09:00', today: today, now: '14:00'),
        isFalse,
      );
    });

    test('something without a time is never overdue', () {
      expect(
        isOverdue(day: today, time: null, today: today, now: '14:00'),
        isFalse,
      );
    });
  });
}
