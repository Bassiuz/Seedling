import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/logic/widget_payload.dart';
import 'package:seedling/models/calendar_event.dart';
import 'package:seedling/models/tag.dart';
import 'package:seedling/models/task.dart';

const _day = '2026-07-27';

Task _task(String title, {String? time, String? tagId, String? done}) => Task(
      id: title,
      title: title,
      date: _day,
      createdDate: _day,
      time: time,
      tagId: tagId,
      completedOnDate: done,
    );

CalendarEvent _event(String title, {String? time, bool allDay = false}) =>
    CalendarEvent(
        id: title, title: title, dayKey: _day, allDay: allDay, time: time);

void main() {
  test('the next timed thing can be an appointment or a task', () {
    final payload = buildWidgetPayload(
      dayKey: _day,
      tasks: [_task('Water the greenhouse', time: '18:00')],
      events: [_event('Dentist appointment', time: '09:00')],
    );

    expect(payload.next, '09:00 Dentist appointment');
  });

  test('a task earlier than every appointment wins', () {
    final payload = buildWidgetPayload(
      dayKey: _day,
      tasks: [_task('Early start', time: '07:00')],
      events: [_event('Dentist appointment', time: '09:00')],
    );

    expect(payload.next, '07:00 Early start');
  });

  test('all-day events are not "next"', () {
    final payload = buildWidgetPayload(
      dayKey: _day,
      tasks: const [],
      events: [_event("Sam's birthday", allDay: true)],
    );

    expect(payload.next, isNull);
  });

  test('finished tasks are left off', () {
    final payload = buildWidgetPayload(
      dayKey: _day,
      tasks: [_task('Afwas doen', done: _day), _task('Still to do')],
      events: const [],
    );

    expect(payload.tasks, ['Still to do']);
  });

  test('only a few fit, and the rest are counted', () {
    final payload = buildWidgetPayload(
      dayKey: _day,
      tasks: [for (var i = 0; i < 7; i++) _task('Task $i')],
      events: const [],
    );

    expect(payload.tasks, hasLength(WidgetPayload.taskLines));
    expect(payload.remaining, 3);
  });

  test('nothing left over means nothing to count', () {
    final payload = buildWidgetPayload(
      dayKey: _day,
      tasks: [_task('Only one')],
      events: const [],
    );

    expect(payload.remaining, 0);
  });

  test('a tagged task carries its project', () {
    final payload = buildWidgetPayload(
      dayKey: _day,
      tasks: [_task('Record voiceover', tagId: 'moxify')],
      events: const [],
      tags: const {
        'moxify': Tag(
            id: 'moxify',
            name: 'Moxify',
            colorIndex: 0,
            iconIndex: 0,
            sortOrder: 0),
      },
    );

    expect(payload.tasks.single, 'Record voiceover · Moxify');
  });

  test('the payload serialises for the widget to read', () {
    final json = buildWidgetPayload(
      dayKey: _day,
      tasks: [_task('Afwas doen')],
      events: const [],
    ).toJson();

    expect(json, contains('"dayKey":"2026-07-27"'));
    expect(json, contains('Afwas doen'));
  });
}
