import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/logic/standup.dart';
import 'package:seedling/models/calendar_event.dart';
import 'package:seedling/models/tag.dart';
import 'package:seedling/models/task.dart';
import 'package:seedling/screens/standup_screen.dart';

import '../util/golden/golden_utils.dart';

const _today = '2026-07-28';
const _yesterday = '2026-07-27';

const _tags = {
  'moxify':
      Tag(id: 'moxify', name: 'Moxify', colorIndex: 6, iconIndex: 1, sortOrder: 0),
};

Task _task(String title,
        {String date = _today, String? done, String? time, String? tagId}) =>
    Task(
        id: title,
        title: title,
        date: date,
        createdDate: date,
        time: time,
        tagId: tagId,
        completedOnDate: done);

final _fixture = [
  _task('Shipped the promo video',
      date: _yesterday, done: _yesterday, tagId: 'moxify'),
  _task('Fixed the rollover bug', date: _yesterday, done: _yesterday),
  _task('Standup', time: '09:30'),
  _task('Write the release notes', tagId: 'moxify'),
  _task('Book the vet', done: _today),
];

CalendarEvent _event(String title,
        {String day = _today, String? time, bool allDay = false}) =>
    CalendarEvent(
        id: title, title: title, dayKey: day, allDay: allDay, time: time);

final _meetings = [
  _event('Sprint planning', time: '10:00'),
  _event('1:1 with Sam', time: '14:00'),
];
final _attended = [_event('Retro', day: _yesterday, time: '15:30')];

Widget _standup(List<Task> tasks,
        {List<CalendarEvent> events = const [],
        List<CalendarEvent> previousEvents = const []}) =>
    StandupView(
      standup: standupFor(tasks, _today,
          events: events, previousEvents: previousEvents),
      tags: _tags,
      name: 'Bas',
    );

void main() {
  goldenForSizes(
    'standup: yesterday done, today planned',
    'standup',
    [GoldenSize.phone, GoldenSize.eink],
    () => _standup(_fixture,
        events: _meetings, previousEvents: _attended),
  );

  goldenForSizes(
    'standup with nothing to report',
    'standup_empty',
    [GoldenSize.phone],
    () => _standup(const []),
  );

  testWidgets('yesterday and today are kept apart', (tester) async {
    await tester.pumpWidget(wrapApp(_standup(_fixture)));

    expect(find.text('Shipped the promo video'), findsOneWidget);
    expect(find.text('Write the release notes'), findsOneWidget);
    // Yesterday's work is not repeated under today.
    expect(find.text('Fixed the rollover bug'), findsOneWidget);
  });

  testWidgets('nothing on the page can be changed', (tester) async {
    await tester.pumpWidget(wrapApp(_standup(_fixture)));

    // No checkboxes, no menus: it is something to read out.
    expect(find.byType(Checkbox), findsNothing);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('something finished today is struck through, not hidden',
      (tester) async {
    await tester.pumpWidget(wrapApp(_standup(_fixture)));

    final done = tester.widget<Text>(find.text('Book the vet'));
    expect(done.style?.decoration, TextDecoration.lineThrough);
  });

  testWidgets('meetings are listed alongside the work', (tester) async {
    await tester.pumpWidget(wrapApp(
      _standup(_fixture, events: _meetings, previousEvents: _attended),
    ));

    expect(find.text('Retro'), findsOneWidget, reason: 'yesterday');
    expect(find.text('Sprint planning'), findsOneWidget, reason: 'today');
  });

  testWidgets('a block with only meetings does not read as empty',
      (tester) async {
    await tester.pumpWidget(wrapApp(
      _standup(const [], previousEvents: _attended),
    ));

    expect(find.text('Retro'), findsOneWidget);
    expect(find.text('Nothing checked off'), findsNothing);
  });

  testWidgets('the copy button puts the whole standup on the clipboard',
      (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.pumpWidget(wrapApp(
      _standup(_fixture, events: _meetings, previousEvents: _attended),
    ));

    await tester.tap(find.byTooltip('Copy for Slack'));
    await tester.pump();

    expect(copied, startsWith('Bas:'));
    expect(copied, contains('    - Retro'), reason: "yesterday's meeting");
    expect(copied, contains('    - Sprint planning'));
    expect(copied, contains('- Vandaag:'));
  });

  group('which day it looks back at', () {
    // 2026-07-27 is a Monday.
    const monday = '2026-07-27';

    Widget screen({Set<String> daysOff = const {}}) => StandupScreen(
          day: monday,
          tasks: [
            _task('Thursday work', date: '2026-07-23', done: '2026-07-23'),
            _task('Tuesday work', date: '2026-07-21', done: '2026-07-21'),
            _task('Friday work', date: '2026-07-24', done: '2026-07-24'),
          ],
          tags: _tags,
          daysOff: daysOff,
          // A distinct meeting per day, so the heading and the meetings under
          // it can be caught disagreeing.
          eventsFor: (key) => [_event('Meeting on $key', day: key)],
        );

    testWidgets('Monday opens on Thursday, not on Sunday', (tester) async {
      await tester.pumpWidget(wrapApp(screen()));

      expect(find.text('Thursday — done'), findsOneWidget);
      expect(find.text('Thursday work'), findsOneWidget);
    });

    testWidgets('the meetings under the heading are that same day\'s',
        (tester) async {
      await tester.pumpWidget(wrapApp(screen()));

      // Thursday heads the block, so Thursday's meeting belongs under it —
      // not literal yesterday's, which is the Sunday.
      expect(find.text('Meeting on 2026-07-23'), findsOneWidget);
      expect(find.text('Meeting on 2026-07-26'), findsNothing);
    });

    testWidgets('shifting the day moves the meetings with it', (tester) async {
      await tester.pumpWidget(wrapApp(screen()));

      await tester.tap(find.byTooltip('A day later'));
      await tester.pumpAndSettle();

      expect(find.text('Friday — done'), findsOneWidget);
      expect(find.text('Meeting on 2026-07-24'), findsOneWidget);
      expect(find.text('Meeting on 2026-07-23'), findsNothing);
    });

    testWidgets('one tap forward reaches the Friday you did work',
        (tester) async {
      await tester.pumpWidget(wrapApp(screen()));

      await tester.tap(find.byTooltip('A day later'));
      await tester.pumpAndSettle();

      expect(find.text('Friday — done'), findsOneWidget);
      expect(find.text('Friday work'), findsOneWidget);
    });

    testWidgets('and back over a Wednesday off to the Tuesday',
        (tester) async {
      await tester.pumpWidget(wrapApp(screen()));

      await tester.tap(find.byTooltip('A day earlier'));
      await tester.tap(find.byTooltip('A day earlier'));
      await tester.pumpAndSettle();

      expect(find.text('Tuesday — done'), findsOneWidget);
    });

    testWidgets('a day marked off is skipped from the start', (tester) async {
      await tester.pumpWidget(wrapApp(screen(daysOff: {'2026-07-23'})));

      expect(find.text('Wednesday — done'), findsOneWidget);
    });

    testWidgets('it cannot be pushed onto the standup day itself',
        (tester) async {
      await tester.pumpWidget(wrapApp(screen()));

      for (var i = 0; i < 6; i++) {
        await tester.tap(find.byTooltip('A day later'));
      }
      await tester.pumpAndSettle();

      // Sunday is as far forward as it goes; Monday is the day itself.
      expect(find.text('Sunday — done'), findsOneWidget);
    });
  });
}
