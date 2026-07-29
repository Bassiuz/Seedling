import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/logic/widget_payload.dart';
import 'package:seedling/models/calendar_event.dart';
import 'package:seedling/models/tag.dart';
import 'package:seedling/models/task.dart';

const _today = '2026-07-28';

Task _task(String title, {String? done, String? tagId, String? time}) => Task(
      id: title,
      title: title,
      date: _today,
      createdDate: _today,
      time: time,
      tagId: tagId,
      completedOnDate: done,
    );

CalendarEvent _event(String title, {String? time, bool allDay = false}) =>
    CalendarEvent(
        id: title, title: title, dayKey: _today, allDay: allDay, time: time);

WidgetPayload _payload({
  List<Task> tasks = const [],
  List<CalendarEvent> events = const [],
  Map<String, Tag> tags = const {},
  Set<String> doneEvents = const {},
  Set<String> pendingDone = const {},
}) =>
    buildWidgetPayload(
      dayKey: _today,
      tasks: tasks,
      events: events,
      tags: tags,
      doneEvents: doneEvents,
      pendingDone: pendingDone,
    );

void main() {
  group('the appointments column', () {
    test('reads in the order the day is lived', () {
      final payload = _payload(events: [
        _event('Retro', time: '16:00'),
        _event('Standup', time: '09:30'),
        _event('Conference', allDay: true),
      ]);

      expect(payload.events.map((e) => e.title),
          ['Conference', 'Standup', 'Retro']);
      expect(payload.events.first.time, 'all day');
    });

    test('one already ticked off is not still waiting for you', () {
      final payload = _payload(
        events: [_event('Standup', time: '09:30')],
        doneEvents: {'Standup'},
      );

      expect(payload.events, isEmpty);
    });

    test('more than fits is counted, not crammed in', () {
      final payload = _payload(events: [
        for (var i = 0; i < 7; i++) _event('Meeting $i', time: '0$i:00'),
      ]);

      expect(payload.events, hasLength(WidgetPayload.lines));
      expect(payload.moreEvents, 3);
    });

    test('an empty day says so with a zero, not a negative', () {
      expect(_payload().moreEvents, 0);
    });
  });

  group('the task column', () {
    test('carries ids, because the widget can check them off', () {
      final payload = _payload(tasks: [_task('Water the greenhouse')]);

      expect(payload.tasks.single.id, 'Water the greenhouse');
    });

    test('what is done is gone — a glance should not skip past it', () {
      final payload = _payload(tasks: [
        _task('Done', done: _today),
        _task('Not done'),
      ]);

      expect(payload.tasks.map((t) => t.title), ['Not done']);
    });

    test('something ticked on the widget is gone before the app agrees', () {
      // The tap is queued, not written; the widget must not show it again in
      // the meantime.
      final payload =
          _payload(tasks: [_task('Tapped')], pendingDone: {'Tapped'});

      expect(payload.tasks, isEmpty);
    });

    test('the tag rides along for the ones that have one', () {
      final payload = _payload(
        tasks: [_task('Fix the trailer', tagId: 'moxify')],
        tags: {
          'moxify': const Tag(
              id: 'moxify',
              name: 'Moxify',
              colorIndex: 0,
              iconIndex: 0,
              sortOrder: 0),
        },
      );

      expect(payload.tasks.single.tag, 'Moxify');
    });

    test('a timed task is still a task', () {
      // It appears on the day page in the timed block, but it is something to
      // do and the widget's right-hand column is what is left to do.
      final payload = _payload(tasks: [_task('Call the bank', time: '11:00')]);

      expect(payload.tasks.single.title, 'Call the bank');
    });
  });

  test('the JSON is the shape the native widgets read', () {
    final json = jsonDecode(_payload(
      tasks: [_task('Water the greenhouse')],
      events: [_event('Standup', time: '09:30')],
    ).toJson()) as Map<String, dynamic>;

    expect(json['dayKey'], _today);
    expect((json['events'] as List).single,
        {'time': '09:30', 'title': 'Standup'});
    expect((json['tasks'] as List).single, {
      'id': 'Water the greenhouse',
      'title': 'Water the greenhouse',
      'tag': null,
    });
    expect(json['moreEvents'], 0);
    expect(json['moreTasks'], 0);
  });
}
