import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/logic/day_pages.dart';

// Monday 27 July 2026 through Sunday 2 August.
const _monday = '2026-07-27';

void main() {
  group('a week of pages', () {
    test('Monday to Sunday are the first seven', () {
      for (final (i, day) in [
        '2026-07-27',
        '2026-07-28',
        '2026-07-29',
        '2026-07-30',
        '2026-07-31',
        '2026-08-01',
        '2026-08-02',
      ].indexed) {
        expect(pageContent(_monday, i).dayKey, day);
        expect(pageForDay(_monday, day), i);
      }
    });

    test('the review comes straight after Sunday', () {
      final slot = pageContent(_monday, 7);

      expect(slot.isReview, isTrue);
      expect(slot.weekKey, '2026-W31');
      expect(slot.dayKey, isNull);
    });

    test('the next Monday follows the review', () {
      expect(pageContent(_monday, 8).dayKey, '2026-08-03');
      expect(pageForDay(_monday, '2026-08-03'), 8);
    });
  });

  group('going backwards', () {
    test('the Sunday before the anchor is followed by its own review', () {
      // Sunday sits two pages back, because its review sits between it and
      // the anchor Monday — the same order as anywhere else.
      expect(pageForDay(_monday, '2026-07-26'), -2);
      expect(pageContent(_monday, -1).isReview, isTrue);
      expect(pageContent(_monday, -1).weekKey, '2026-W30');
    });

    test('the previous week reads Monday to Sunday too', () {
      expect(pageContent(_monday, -8).dayKey, '2026-07-20');
      expect(pageContent(_monday, -2).dayKey, '2026-07-26');
    });

    test('a day well in the past round-trips', () {
      const old = '2026-05-13';
      expect(pageContent(_monday, pageForDay(_monday, old)).dayKey, old);
    });
  });

  test('every day round-trips through its page, across many weeks', () {
    var day = '2026-01-01';
    for (var i = 0; i < 400; i++) {
      expect(pageContent(_monday, pageForDay(_monday, day)).dayKey, day,
          reason: 'day $day');
      day = _next(day);
    }
  });

  test('a review page is reachable from any day of its week', () {
    for (final day in [
      '2026-07-27',
      '2026-07-30',
      '2026-08-02',
    ]) {
      final page = pageForReviewOfWeekContaining(_monday, day);
      expect(pageContent(_monday, page).weekKey, '2026-W31');
    }
  });

  test('pages never collide: each index means exactly one thing', () {
    final seen = <String>{};
    for (var i = -20; i < 20; i++) {
      final slot = pageContent(_monday, i);
      final id = slot.isReview ? 'w:${slot.weekKey}' : 'd:${slot.dayKey}';
      expect(seen.add(id), isTrue, reason: '$id appeared twice');
    }
  });
}

String _next(String day) {
  final d = DateTime.parse(day);
  final n = DateTime(d.year, d.month, d.day + 1);
  return '${n.year.toString().padLeft(4, '0')}-'
      '${n.month.toString().padLeft(2, '0')}-'
      '${n.day.toString().padLeft(2, '0')}';
}
