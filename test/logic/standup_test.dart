import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/logic/standup.dart';
import 'package:seedling/models/calendar_event.dart';
import 'package:seedling/models/task.dart';

const _today = '2026-07-28';
const _yesterday = '2026-07-27';

Task _task(String title,
        {String date = _today, String? done, String? time}) =>
    Task(
        id: title,
        title: title,
        date: date,
        createdDate: date,
        time: time,
        completedOnDate: done);

void main() {
  test('yesterday is the day before, across a month boundary', () {
    expect(standupFor(const [], '2026-08-01').previousDay, '2026-07-31');
  });

  test('what was checked off yesterday is what you did', () {
    final standup = standupFor([
      _task('Shipped the promo', date: _yesterday, done: _yesterday),
      _task('Still open', date: _yesterday),
    ], _today);

    expect(standup.done.map((t) => t.title), ['Shipped the promo']);
  });

  test('a task planned long ago but finished yesterday still counts', () {
    final standup = standupFor(
      [_task('Long haul', date: '2026-07-01', done: _yesterday)],
      _today,
    );

    expect(standup.done.map((t) => t.title), ['Long haul']);
  });

  test('something finished today is not part of yesterday', () {
    final standup =
        standupFor([_task('Just now', done: _today)], _today);

    expect(standup.done, isEmpty);
    expect(standup.planned.map((t) => t.title), ['Just now']);
  });

  test("today's list includes what is already done", () {
    final standup = standupFor([
      _task('Done already', done: _today),
      _task('Still to do'),
    ], _today);

    expect(standup.planned, hasLength(2));
  });

  test('an unfinished task from an earlier day carries into today', () {
    final standup =
        standupFor([_task('Rolled over', date: '2026-07-20')], _today);

    expect(standup.planned.map((t) => t.title), ['Rolled over']);
  });

  test('timed work is read out in clock order, before the untimed', () {
    final standup = standupFor([
      _task('Untimed'),
      _task('Standup', time: '09:30'),
      _task('Retro', time: '16:00'),
    ], _today);

    expect(standup.planned.map((t) => t.title),
        ['Standup', 'Retro', 'Untimed']);
  });

  group('meetings', () {
    CalendarEvent event(String title, {String? time, bool allDay = false}) =>
        CalendarEvent(
            id: title,
            title: title,
            dayKey: _today,
            allDay: allDay,
            time: time);

    test('yesterday and today keep their own', () {
      final standup = standupFor(
        const [],
        _today,
        events: [event('Planning', time: '10:00')],
        previousEvents: [event('Retro', time: '15:00')],
      );

      expect(standup.meetings.map((e) => e.title), ['Planning']);
      expect(standup.attended.map((e) => e.title), ['Retro']);
    });

    test('they are read out in the order they happen', () {
      final standup = standupFor(const [], _today, events: [
        event('Retro', time: '16:00'),
        event('Standup', time: '09:30'),
      ]);

      expect(standup.meetings.map((e) => e.title), ['Standup', 'Retro']);
    });

    test('an all-day thing comes before the timed ones', () {
      final standup = standupFor(const [], _today, events: [
        event('Standup', time: '09:30'),
        event('Conference', allDay: true),
      ]);

      expect(standup.meetings.map((e) => e.title), ['Conference', 'Standup']);
    });

    test('a day with no calendar at all still builds', () {
      expect(standupFor(const [], _today).meetings, isEmpty);
    });
  });
}
