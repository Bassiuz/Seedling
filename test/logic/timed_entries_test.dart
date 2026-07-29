import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/logic/timed_entries.dart';
import 'package:seedling/models/calendar_event.dart';
import 'package:seedling/models/task.dart';

const _day = '2026-07-28';

CalendarEvent _event(String title, {String? time, bool allDay = false}) =>
    CalendarEvent(
        id: title, title: title, dayKey: _day, allDay: allDay, time: time);

Task _task(String title, {String? time}) => Task(
    id: title, title: title, date: _day, createdDate: _day, time: time);

void main() {
  test('appointments and timed tasks are interleaved by the clock', () {
    final entries = timedEntries(
      [_event('Dentist appointment', time: '09:00'), _event('Standup', time: '17:00')],
      [_task('Water the greenhouse', time: '12:00'), _task('Early call', time: '08:00')],
    );

    expect(entries.map((e) => e.title).toList(), [
      'Early call',
      'Dentist appointment',
      'Water the greenhouse',
      'Standup',
    ]);
  });

  test('all-day events head the list', () {
    final entries = timedEntries(
      [_event('Vet', time: '09:00'), _event("Sam's birthday", allDay: true)],
      [_task('Early call', time: '07:00')],
    );

    expect(entries.first.title, "Sam's birthday");
    expect(entries.first.allDay, isTrue);
  });

  test('untimed tasks are left out entirely', () {
    final entries = timedEntries(const [], [
      _task('Afwas doen'),
      _task('Vet', time: '09:00'),
    ]);

    expect(entries.map((e) => e.title).toList(), ['Vet']);
  });

  test('same time falls back to the title so the order is stable', () {
    final entries = timedEntries(
      [_event('Beta', time: '09:00')],
      [_task('alpha', time: '09:00')],
    );

    expect(entries.map((e) => e.title).toList(), ['alpha', 'Beta']);
  });

  test('an entry knows which kind it is', () {
    final entries = timedEntries([_event('Vet', time: '09:00')],
        [_task('Call', time: '10:00')]);

    expect(entries.first.isEvent, isTrue);
    expect(entries.first.event, isNotNull);
    expect(entries.last.isEvent, isFalse);
    expect(entries.last.task, isNotNull);
  });

  test('ids do not collide between an event and a task of the same name', () {
    final entries =
        timedEntries([_event('Standup', time: '09:00')], [_task('Standup', time: '09:00')]);

    expect(entries.first.id, isNot(entries.last.id));
  });

  test('nothing in, nothing out', () {
    expect(timedEntries(const [], const []), isEmpty);
  });
}
