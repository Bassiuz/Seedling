import 'dart:convert';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:seedling/data/calendar_source.dart';
import 'package:seedling/data/jira_account.dart';
import 'package:seedling/data/jira_client.dart';
import 'package:seedling/data/seedling_repo.dart';
import 'package:seedling/logic/day_key.dart';
import 'package:seedling/logic/jira_ref.dart';
import 'package:seedling/logic/timesheet.dart';
import 'package:seedling/models/calendar_event.dart';
import 'package:seedling/models/event_extras.dart';
import 'package:seedling/models/topic.dart';
import 'package:seedling/screens/timesheet_screen.dart';

import '../util/golden/golden_utils.dart';

const _monday = '2026-07-27';
const _site = 'https://example.atlassian.net';

TimesheetRow _row(String title, String key, List<int> minutes,
        {Topic? topic}) =>
    TimesheetRow(
      sourceId: title,
      title: title,
      jira: JiraRef(key: key, site: _site),
      minutes: minutes,
      topic: topic,
    );

/// Never touches a keychain.
class _FakeAccount implements JiraAccount {
  _FakeAccount([this.stored]);

  ({String email, String token})? stored;

  @override
  Future<({String email, String token})?> read() async => stored;

  @override
  Future<void> save({required String email, required String token}) async =>
      stored = (email: email, token: token);

  @override
  Future<void> forget() async => stored = null;
}

void main() {
  goldenForSizes(
    'timesheet: a week of work and the standing rows under it',
    'timesheet',
    [GoldenSize.mac, GoldenSize.eink],
    () => TimesheetView(
      anyDay: _monday,
      signedInAs: 'you@example.com',
      pending: 3,
      onSend: () {},
      onEdit: (_, _, _) {},
      onAddTopic: () {},
      onWeek: (_) {},
      taskLines: [
        _row('Retry voor Autoclicker', 'AT-4496', [0, 420, 420, 240, 0, 0, 0]),
        _row('Controle van geplande leveringen', 'AT-4544',
            [60, 0, 0, 0, 90, 0, 0]),
      ],
      topicLines: [
        _row('Meetings', 'MAF-4319', [120, 120, 240, 0, 60, 0, 0],
            topic: const Topic(id: 'meetings', title: 'Meetings')),
        _row('Wordpress onderhoud', 'MAF-4775', [0, 0, 0, 360, 0, 0, 0],
            topic: const Topic(id: 'wp', title: 'Wordpress onderhoud')),
      ],
    ),
  );

  goldenForSizes(
    'timesheet with a day off in the middle of it',
    'timesheet_day_off',
    [GoldenSize.mac],
    () => TimesheetView(
      anyDay: _monday,
      signedInAs: 'you@example.com',
      daysOff: const {'2026-07-29'},
      onEdit: (_, _, _) {},
      onToggleDayOff: (_) {},
      taskLines: [
        _row('Retry voor Autoclicker', 'AT-4496', [0, 420, 0, 240, 0, 0, 0]),
      ],
      topicLines: [
        _row('Meetings', 'MAF-4319', [120, 120, 0, 0, 60, 0, 0]),
      ],
    ),
  );

  goldenForSizes(
    'timesheet with nothing in it yet',
    'timesheet_empty',
    [GoldenSize.mac],
    () => const TimesheetView(
      anyDay: _monday,
      taskLines: [],
      topicLines: [],
      signedInAs: 'you@example.com',
    ),
  );

  testWidgets('the arrows move a week at a time', (tester) async {
    configureSize(tester, GoldenSize.mac);
    final moves = <int>[];
    await tester.pumpWidget(wrapApp(TimesheetView(
      anyDay: _monday,
      taskLines: const [],
      topicLines: const [],
      onWeek: moves.add,
    )));

    await tester.tap(find.byTooltip('The week before'));
    await tester.tap(find.byTooltip('The week after'));

    expect(moves, [-1, 1]);
  });

  testWidgets('the weekend is not drawn when nothing was logged on it',
      (tester) async {
    configureSize(tester, GoldenSize.mac);
    await tester.pumpWidget(wrapApp(TimesheetView(
      anyDay: _monday,
      taskLines: [_row('A', 'AT-1', [60, 0, 0, 0, 0, 0, 0])],
      topicLines: const [],
    )));

    expect(find.text('Fr'), findsWidgets);
    expect(find.text('Sa'), findsNothing);
    expect(find.text('Su'), findsNothing);
  });

  testWidgets('a Saturday you did work gets its column back', (tester) async {
    configureSize(tester, GoldenSize.mac);
    await tester.pumpWidget(wrapApp(TimesheetView(
      anyDay: _monday,
      taskLines: [_row('A', 'AT-1', [0, 0, 0, 0, 0, 90, 0])],
      topicLines: const [],
    )));

    expect(find.text('Sa'), findsWidgets);
    expect(find.text('Su'), findsNothing);
  });

  testWidgets('the totals add both grids up, day by day', (tester) async {
    configureSize(tester, GoldenSize.mac);
    await tester.pumpWidget(wrapApp(TimesheetView(
      anyDay: _monday,
      taskLines: [_row('A', 'AT-1', [60, 0, 0, 0, 0, 0, 0])],
      topicLines: [_row('Meetings', 'MAF-1', [30, 90, 0, 0, 0, 0, 0])],
      signedInAs: 'you@example.com',
    )));

    // Monday: 1:00 of task work plus 0:30 of meetings. The week: 3:00.
    expect(find.text('1:30'), findsWidgets, reason: "Monday's total");
    expect(find.text('3:00'), findsOneWidget, reason: 'the week');
  });

  testWidgets('a row without a ticket says so', (tester) async {
    configureSize(tester, GoldenSize.mac);
    await tester.pumpWidget(wrapApp(TimesheetView(
      anyDay: _monday,
      taskLines: const [],
      topicLines: [
        const TimesheetRow(
          sourceId: 'x',
          title: 'Meetings',
          minutes: [0, 0, 0, 0, 0, 0, 0],
          topic: Topic(id: 'x', title: 'Meetings'),
        ),
      ],
    )));

    // Without one its hours have nowhere to go, which is worth seeing.
    expect(find.text('no ticket'), findsOneWidget);
  });

  testWidgets('with nothing out of step there is nothing to send',
      (tester) async {
    configureSize(tester, GoldenSize.mac);
    await tester.pumpWidget(wrapApp(const TimesheetView(
      anyDay: _monday,
      taskLines: [],
      topicLines: [],
      signedInAs: 'you@example.com',
    )));

    expect(find.text('Jira has this week already.'), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('typing into a cell logs that day', (tester) async {
    configureSize(tester, GoldenSize.mac);
    final edits = <(String, String, int)>[];
    await tester.pumpWidget(wrapApp(TimesheetView(
      anyDay: _monday,
      taskLines: [_row('Retry', 'AT-1', [0, 0, 0, 0, 0, 0, 0])],
      topicLines: const [],
      onEdit: (row, day, minutes) => edits.add((row.title, day, minutes)),
    )));

    await tester.tap(find.byKey(const ValueKey('cell:Retry@$_monday')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '3:15');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(edits, [('Retry', _monday, 195)]);
  });

  testWidgets('a ticketed meeting gets a row and takes hours', (tester) async {
    configureSize(tester, GoldenSize.mac);
    final repo = SeedlingRepo(FakeFirebaseFirestore(), 'bas');
    await repo.setEventExtras('Acceptance test',
        const EventExtras(jira: JiraRef(key: 'MAF-4836', site: _site)));

    await tester.pumpWidget(wrapApp(TimesheetScreen(
      repo: repo,
      account: _FakeAccount(),
      calendar: FakeCalendar([
        CalendarEvent(
          id: 'at@${todayKey()}',
          title: 'Acceptance test',
          dayKey: todayKey(),
          allDay: false,
          time: '13:45',
        ),
      ]),
    )));
    await tester.pumpAndSettle();

    expect(find.text('Meetings'), findsOneWidget);

    await tester
        .tap(find.byKey(ValueKey('cell:Acceptance test@${todayKey()}')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '2:00');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final extras = (await repo.watchEventExtras().first)['Acceptance test']!;
    expect(extras.minutesOn(todayKey()), 120);
    expect(extras.jira?.key, 'MAF-4836', reason: 'the ticket must survive');
    expect(find.text('2:00'), findsWidgets);
  });

  testWidgets('a meeting with no ticket leaves the section out',
      (tester) async {
    configureSize(tester, GoldenSize.mac);
    final repo = SeedlingRepo(FakeFirebaseFirestore(), 'bas');

    await tester.pumpWidget(wrapApp(TimesheetScreen(
      repo: repo,
      account: _FakeAccount(),
      calendar: FakeCalendar([
        CalendarEvent(
          id: 'lunch@${todayKey()}',
          title: 'Lunch',
          dayKey: todayKey(),
          allDay: false,
          time: '12:00',
        ),
      ]),
    )));
    await tester.pumpAndSettle();

    expect(find.text('Meetings'), findsNothing);
  });

  testWidgets('sending puts the week in Jira and remembers it', (tester) async {
    configureSize(tester, GoldenSize.mac);
    final repo = SeedlingRepo(FakeFirebaseFirestore(), 'bas');
    await repo.upsertTopic(Topic(
      id: 'meetings',
      title: 'Meetings',
      jira: const JiraRef(key: 'MAF-4319', site: _site),
      minutes: {todayKey(): 120},
    ));

    var posts = 0;
    await tester.pumpWidget(wrapApp(TimesheetScreen(
      repo: repo,
      account: _FakeAccount((email: 'you@example.com', token: 'secret')),
      clientFor: (site, email, token) => JiraClient(
        site: site,
        email: email,
        apiToken: token,
        httpClient: MockClient((_) async {
          posts++;
          return http.Response(jsonEncode({'id': '10123'}), 201);
        }),
      ),
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Send this week to Jira'));
    await tester.pumpAndSettle();

    expect(posts, 1);
    expect((await repo.watchSentWorklogs().first).values.single.minutes, 120);
    expect(find.text('Jira has this week already.'), findsOneWidget);
  });

  group('a day off', () {
    testWidgets('is set by tapping its heading', (tester) async {
      configureSize(tester, GoldenSize.mac);
      final toggled = <String>[];
      await tester.pumpWidget(wrapApp(TimesheetView(
        anyDay: _monday,
        taskLines: [_row('A', 'AT-1', [0, 0, 0, 0, 0, 0, 0])],
        topicLines: const [],
        onToggleDayOff: toggled.add,
      )));

      // Each grid carries its own heading row; either one closes the day.
      await tester.tap(find.text('Fr').first);

      expect(toggled, ['2026-07-31']);
    });

    testWidgets('closes its column to typing', (tester) async {
      configureSize(tester, GoldenSize.mac);
      final edits = <String>[];
      await tester.pumpWidget(wrapApp(TimesheetView(
        anyDay: _monday,
        taskLines: [_row('A', 'AT-1', [0, 0, 0, 0, 0, 0, 0])],
        topicLines: const [],
        daysOff: const {'2026-07-29'},
        onEdit: (_, day, _) => edits.add(day),
      )));

      await tester.tap(find.byKey(const ValueKey('cell:A@2026-07-29')));
      await tester.pumpAndSettle();

      expect(find.text('Save'), findsNothing, reason: 'no dialog opened');
      expect(edits, isEmpty);
    });

    testWidgets('the days either side still take a number', (tester) async {
      configureSize(tester, GoldenSize.mac);
      final edits = <String>[];
      await tester.pumpWidget(wrapApp(TimesheetView(
        anyDay: _monday,
        taskLines: [_row('A', 'AT-1', [0, 0, 0, 0, 0, 0, 0])],
        topicLines: const [],
        daysOff: const {'2026-07-29'},
        onEdit: (_, day, _) => edits.add(day),
      )));

      await tester.tap(find.byKey(const ValueKey('cell:A@2026-07-28')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '2');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(edits, ['2026-07-28']);
    });

    testWidgets('an hour already logged on it is still shown', (tester) async {
      // Marking a day off is a guard against typing, not a reason to hide
      // something you would want to notice and move.
      configureSize(tester, GoldenSize.mac);
      await tester.pumpWidget(wrapApp(TimesheetView(
        anyDay: _monday,
        taskLines: [_row('A', 'AT-1', [0, 0, 90, 0, 0, 0, 0])],
        topicLines: const [],
        daysOff: const {'2026-07-29'},
      )));

      expect(find.text('1:30'), findsWidgets);
    });
  });
}
