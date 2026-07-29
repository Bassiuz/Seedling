import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/logic/jira_ref.dart';
import 'package:seedling/models/calendar_event.dart';
import 'package:seedling/models/event_extras.dart';
import 'package:seedling/models/tag.dart';
import 'package:seedling/models/task.dart';
import 'package:seedling/widgets/task_tile.dart';
import 'package:seedling/widgets/timed_block.dart';

import '../util/golden/golden_utils.dart';

const _today = '2026-07-28';

CalendarEvent _event(String title, {String? time, bool allDay = false}) =>
    CalendarEvent(
        id: title, title: title, dayKey: _today, allDay: allDay, time: time);

Task _task(String title, {String? time, String? done}) => Task(
      id: title,
      title: title,
      date: _today,
      createdDate: _today,
      time: time,
      completedOnDate: done,
    );

Widget _block({
  List<CalendarEvent> events = const [],
  List<Task> tasks = const [],
  Set<String> doneEvents = const {},
  Map<String, EventExtras> eventExtras = const {},
  Map<String, Tag> tags = const {},
  String? now,
  void Function(CalendarEvent, bool)? onToggleEvent,
  void Function(String, {String? tagId, String? time})? onAdd,
}) =>
    Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: TimedBlock(
            tasks: tasks,
            tags: tags,
            shownDay: _today,
            today: _today,
            now: now,
            events: events,
            doneEvents: doneEvents,
            eventExtras: eventExtras,
            onToggleEvent: onToggleEvent ?? (_, _) {},
            onToggle: (_) {},
            onMenu: (_) {},
            onAdd: onAdd,
          ),
        ),
      ),
    );

void main() {
  goldenForSizes(
    'timed block: appointments and tasks interleaved, one overdue',
    'timed_interleaved',
    [GoldenSize.phone],
    () => _block(
      now: '14:00',
      events: [
        _event("Sam's birthday", allDay: true),
        _event('Dentist appointment', time: '09:00'),
        _event('Standup', time: '17:00'),
      ],
      tasks: [
        _task('Water the greenhouse', time: '12:00'),
        _task('Take the bins out', time: '19:00'),
      ],
      onAdd: (_, {tagId, time}) {},
    ),
  );

  testWidgets('appointments and timed tasks are in one clock order',
      (tester) async {
    await tester.pumpWidget(wrapApp(_block(
      events: [_event('Standup', time: '17:00')],
      tasks: [_task('Early call', time: '08:00')],
    )));

    final early = tester.getTopLeft(find.text('Early call')).dy;
    final standup = tester.getTopLeft(find.text('Standup')).dy;

    expect(early, lessThan(standup),
        reason: 'the 08:00 task belongs above the 17:00 appointment');
  });

  testWidgets('an appointment can be ticked off', (tester) async {
    final ticks = <(String, bool)>[];
    await tester.pumpWidget(wrapApp(_block(
      events: [_event('Dentist appointment', time: '09:00')],
      onToggleEvent: (e, done) => ticks.add((e.title, done)),
    )));

    await tester.tap(find.byType(TaskCheckbox));

    expect(ticks, [('Dentist appointment', true)]);
  });

  testWidgets('a ticked appointment can be unticked', (tester) async {
    final ticks = <(String, bool)>[];
    await tester.pumpWidget(wrapApp(_block(
      events: [_event('Dentist appointment', time: '09:00')],
      doneEvents: const {'Dentist appointment'},
      onToggleEvent: (e, done) => ticks.add((e.title, done)),
    )));

    await tester.tap(find.byType(TaskCheckbox));

    expect(ticks, [('Dentist appointment', false)]);
  });

  testWidgets('something still open whose time has passed reads as overdue',
      (tester) async {
    await tester.pumpWidget(wrapApp(_block(
      now: '14:00',
      events: [_event('Dentist appointment', time: '09:00')],
      tasks: [_task('Later thing', time: '17:00')],
    )));

    expect(find.textContaining('Overdue'), findsOneWidget);
  });

  testWidgets('a ticked-off appointment is not overdue', (tester) async {
    await tester.pumpWidget(wrapApp(_block(
      now: '14:00',
      events: [_event('Dentist appointment', time: '09:00')],
      doneEvents: const {'Dentist appointment'},
    )));

    expect(find.textContaining('Overdue'), findsNothing);
  });

  testWidgets('a finished task is not overdue either', (tester) async {
    await tester.pumpWidget(wrapApp(_block(
      now: '14:00',
      tasks: [_task('Done thing', time: '09:00', done: _today)],
    )));

    expect(find.textContaining('Overdue'), findsNothing);
  });

  testWidgets('nothing is overdue when the clock is unknown', (tester) async {
    await tester.pumpWidget(wrapApp(_block(
      events: [_event('Dentist appointment', time: '09:00')],
    )));

    expect(find.textContaining('Overdue'), findsNothing);
  });

  testWidgets('the add line asks for a time before adding', (tester) async {
    final added = <(String, String?)>[];
    await tester.pumpWidget(wrapApp(_block(
      onAdd: (title, {tagId, time}) => added.add((title, time)),
    )));

    await tester.enterText(
        find.widgetWithText(TextField, 'Add at a time…'), 'Call the vet');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // The time picker is up; nothing has been added yet.
    expect(added, isEmpty);
    expect(find.byType(TimePickerDialog), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(added, hasLength(1));
    expect(added.single.$1, 'Call the vet');
    expect(added.single.$2, isNotNull, reason: 'it got a time');
  });

  testWidgets('dismissing the picker adds nothing', (tester) async {
    final added = <String>[];
    await tester.pumpWidget(wrapApp(_block(
      onAdd: (title, {tagId, time}) => added.add(title),
    )));

    await tester.enterText(
        find.widgetWithText(TextField, 'Add at a time…'), 'Call the vet');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(added, isEmpty);
  });

  group('what Seedling adds to an appointment', () {
    const tag = Tag(
        id: 'moxify', name: 'Moxify', colorIndex: 6, iconIndex: 1,
        sortOrder: 0);

    testWidgets('the tag, the ticket and the logged time all show up',
        (tester) async {
      await tester.pumpWidget(wrapApp(_block(
        events: [_event('Standup', time: '09:00')],
        tags: const {'moxify': tag},
        eventExtras: {
          'Standup': const EventExtras(
            tagId: 'moxify',
            jira: JiraRef(key: 'MAF-12', site: 'https://m.atlassian.net'),
          ).withMinutes(_today, 45),
        },
      )));

      expect(find.text('Moxify'), findsOneWidget);
      expect(find.text('MAF-12'), findsOneWidget);
      expect(find.textContaining('45m'), findsOneWidget);
    });

    testWidgets('time logged on another day is not shown on this one',
        (tester) async {
      await tester.pumpWidget(wrapApp(_block(
        events: [_event('Standup', time: '09:00')],
        eventExtras: {
          'Standup': const EventExtras().withMinutes('2026-07-27', 45),
        },
      )));

      expect(find.textContaining('45m'), findsNothing);
    });
  });
}
