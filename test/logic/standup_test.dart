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
  group('which day it looks back at', () {
    // 2026-07-27 is a Monday.
    const monday = '2026-07-27';
    const tuesday = '2026-07-28';
    const wednesday = '2026-07-29';
    const thursday = '2026-07-30';
    const friday = '2026-07-31';

    test('Monday looks back at Thursday, not the weekend', () {
      expect(previousWorkingDay(monday), '2026-07-23');
    });

    test('Tuesday looks back at Monday', () {
      expect(previousWorkingDay(tuesday), monday);
    });

    test('a Wednesday off makes Thursday look back at Tuesday', () {
      expect(previousWorkingDay(thursday, daysOff: {wednesday}), tuesday);
    });

    test('two days off in a row are both stepped over', () {
      expect(previousWorkingDay(thursday, daysOff: {wednesday, tuesday}),
          monday);
    });

    test('someone who works Fridays says so, and Monday follows', () {
      expect(
        previousWorkingDay(monday, workingDays: {
          DateTime.monday,
          DateTime.tuesday,
          DateTime.wednesday,
          DateTime.thursday,
          DateTime.friday,
        }),
        '2026-07-24',
      );
    });

    test('a fortnight of nothing falls back on yesterday', () {
      // Better a wrong day than an empty screen; the settings are the bug.
      expect(previousWorkingDay(monday, workingDays: const {}), '2026-07-26');
    });

    test('it crosses a month boundary without trouble', () {
      // Saturday 1 August looks back at Thursday 30 July.
      expect(previousWorkingDay('2026-08-01'), thursday);
    });

    test('the standup takes the override when it is given one', () {
      expect(standupFor(const [], monday, previousDay: friday).previousDay,
          friday);
    });

    test('and works it out itself when it is not', () {
      expect(standupFor(const [], monday).previousDay, '2026-07-23');
    });
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

  group('as text for Slack', () {
    CalendarEvent meeting(String title, {String day = _today}) => CalendarEvent(
        id: title, title: title, dayKey: day, allDay: false, time: '10:00');

    Standup full() => standupFor(
          [
            _task('Bugboard', date: _yesterday, done: _yesterday),
            _task('Desk tickets'),
          ],
          _today,
          events: [meeting('NPS review')],
          previousEvents: [meeting('Retro', day: _yesterday)],
        );

    test('reads as two bulleted sections', () {
      expect(standupText(full(), name: 'Bas'), '''
Bas:
- Gisteren:
    - Retro
    - Bugboard
- Vandaag:
    - NPS review
    - Desk tickets''');
    });

    test('no name means no name line', () {
      expect(standupText(full()).startsWith('- Gisteren:'), isTrue);
    });

    test('a blank name is the same as none', () {
      expect(standupText(full(), name: '   ').startsWith('- Gisteren:'), isTrue);
    });

    test('an empty day still carries its heading', () {
      // A standup that says nothing is still a standup you have to give.
      expect(standupText(standupFor(const [], _today)), '''
- Gisteren:
- Vandaag:''');
    });
  });
}
