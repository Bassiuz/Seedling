import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/logic/blacklist.dart';
import 'package:seedling/models/calendar_event.dart';

CalendarEvent _event(
  String title, {
  String? time,
  bool allDay = false,
  String? recurringId,
}) =>
    CalendarEvent(
      id: title,
      title: title,
      dayKey: '2026-07-27',
      allDay: allDay,
      time: time,
      recurringId: recurringId,
    );

void main() {
  test('a repeating event is matched by its series, not its title', () {
    final bins = _event('Bins out', time: '19:00', recurringId: 'series-1');

    expect(isHidden(bins, {'series-1'}), isTrue);
    expect(isHidden(bins, {'Bins out'}), isFalse,
        reason: 'the series id wins when there is one');
  });

  test('a one-off event is matched by its exact title', () {
    final lunch = _event('Lunch with Rik', time: '12:00');

    expect(isHidden(lunch, {'Lunch with Rik'}), isTrue);
    expect(isHidden(lunch, {'Lunch'}), isFalse, reason: 'exact match only');
  });

  test('hidden events are dropped from the day', () {
    final events = [
      _event('Vet appointment', time: '09:00'),
      _event('Water the plants', time: '08:00', recurringId: 'plants'),
    ];

    expect(
      visibleEvents(events, {'plants'}).map((e) => e.title).toList(),
      ['Vet appointment'],
    );
  });

  test('reveal brings the hidden ones back so a mistake can be undone', () {
    final events = [
      _event('Vet appointment', time: '09:00'),
      _event('Water the plants', time: '08:00', recurringId: 'plants'),
    ];

    expect(
      visibleEvents(events, {'plants'}, reveal: true).map((e) => e.title),
      ['Water the plants', 'Vet appointment'],
    );
  });

  test('all-day events come before timed ones, then it is by the clock', () {
    final events = [
      _event('Evening thing', time: '20:00'),
      _event("Joan's birthday", allDay: true),
      _event('Morning thing', time: '08:00'),
    ];

    expect(
      visibleEvents(events, const {}).map((e) => e.title).toList(),
      ["Joan's birthday", 'Morning thing', 'Evening thing'],
    );
  });

  test('same-time events fall back to the title so order is stable', () {
    final events = [
      _event('Beta', time: '09:00'),
      _event('Alpha', time: '09:00'),
    ];

    expect(visibleEvents(events, const {}).map((e) => e.title).toList(),
        ['Alpha', 'Beta']);
  });

  test('nothing hidden means nothing dropped', () {
    final events = [_event('Vet appointment', time: '09:00')];

    expect(visibleEvents(events, const {}), hasLength(1));
  });
}
