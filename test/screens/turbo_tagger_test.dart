import 'dart:convert';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:seedling/data/jira_account.dart';
import 'package:seedling/data/jira_client.dart';
import 'package:seedling/data/seedling_repo.dart';
import 'package:seedling/logic/day_key.dart';
import 'package:seedling/logic/jira_ref.dart';
import 'package:seedling/models/jira_ticket.dart';
import 'package:seedling/models/task.dart';
import 'package:seedling/screens/turbo_tagger_screen.dart';

import '../util/golden/golden_utils.dart';

const _site = 'https://example.atlassian.net';

Task _task(String title, {String? date, JiraRef? jira}) => Task(
      id: title,
      title: title,
      date: date ?? todayKey(),
      createdDate: date ?? todayKey(),
      jira: jira,
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

Widget _screen(SeedlingRepo repo, {MockClient? jira, bool account = true}) =>
    TurboTaggerScreen(
      repo: repo,
      today: todayKey(),
      account: _FakeAccount(
          account ? (email: 'you@example.com', token: 'secret') : null),
      clientFor: (site, email, token) => JiraClient(
        site: site,
        email: email,
        apiToken: token,
        httpClient: jira ?? MockClient((_) async => http.Response('{}', 200)),
      ),
    );

void main() {
  goldenForSizes(
    'turbo tagger: a day of work with no tickets on it',
    'turbo_tagger',
    [GoldenSize.phone, GoldenSize.mac],
    () => TurboTaggerView(
      dayKey: '2026-07-28',
      ticketCount: 12,
      onDay: (_) {},
      onTag: (_) {},
      onImport: () {},
      tasks: [
        _task('Rework the importer'),
        _task('Draft the newsletter'),
        _task('Edit the onboarding copy'),
      ],
    ),
  );

  goldenForSizes(
    'turbo tagger with nothing left to tag',
    'turbo_tagger_clean',
    [GoldenSize.phone],
    () => const TurboTaggerView(dayKey: '2026-07-28', tasks: []),
  );

  testWidgets('only work without a ticket is listed', (tester) async {
    configureSize(tester, GoldenSize.mac);
    final repo = SeedlingRepo(FakeFirebaseFirestore(), 'bas');
    await repo.addTask('Needs one', date: todayKey());
    await repo.addTask('Already tagged', date: todayKey());
    final tagged = (await repo.watchTasks().first)
        .firstWhere((t) => t.title == 'Already tagged');
    await repo.setJira(tagged, const JiraRef(key: 'AT-1', site: _site));

    await tester.pumpWidget(wrapApp(_screen(repo)));
    await tester.pumpAndSettle();

    expect(find.text('Needs one'), findsOneWidget);
    expect(find.text('Already tagged'), findsNothing);
  });

  testWidgets('a pasted blob becomes tickets, named by Jira', (tester) async {
    configureSize(tester, GoldenSize.mac);
    final repo = SeedlingRepo(FakeFirebaseFirestore(), 'bas');
    await repo.rememberJiraSite(_site);

    final jira = MockClient((_) async => http.Response(
          jsonEncode({
            'issues': [
              {'key': 'AT-4496', 'fields': {'summary': 'Retry the autoclicker'}},
              {'key': 'MAF-4319', 'fields': {'summary': 'Meetings'}},
            ]
          }),
          200,
        ));

    await tester.pumpWidget(wrapApp(_screen(repo, jira: jira)));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Paste in some tickets'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField),
        'AT-4496 and https://example.atlassian.net/browse/MAF-4319, plus UTF-8');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    final stored = await repo.watchJiraTickets().first;
    expect(stored.map((t) => t.key).toSet(), {'AT-4496', 'MAF-4319'},
        reason: 'UTF-8 looked like a key; Jira did not know it');
    expect(stored.firstWhere((t) => t.key == 'AT-4496').summary,
        'Retry the autoclicker');
  });

  testWidgets('a failed lookup shows the real error, not the connect hint',
      (tester) async {
    configureSize(tester, GoldenSize.mac);
    final repo = SeedlingRepo(FakeFirebaseFirestore(), 'bas');
    await repo.rememberJiraSite(_site);

    final jira = MockClient((_) async => http.Response('nope', 401));

    await tester.pumpWidget(wrapApp(_screen(repo, jira: jira)));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Paste in some tickets'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField),
        'https://example.atlassian.net/browse/AT-4496 and MAF-4319');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(
        find.text('Added 2 without names — Jira would not accept the login. '
            'Check the email and API token.'),
        findsOneWidget);
    // The paste is still kept, just unnamed.
    expect((await repo.watchJiraTickets().first).length, 2);
  });

  testWidgets('picking a ticket tags the task and logs the hour',
      (tester) async {
    configureSize(tester, GoldenSize.mac);
    final repo = SeedlingRepo(FakeFirebaseFirestore(), 'bas');
    await repo.addTask('Needs one', date: todayKey());
    await repo.rememberJiraTickets([
      const JiraTicket(key: 'AT-4496', site: _site, summary: 'Retry it'),
    ]);

    await tester.pumpWidget(wrapApp(_screen(repo)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Needs one'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retry it'));
    await tester.pumpAndSettle();

    // An hour is offered, because it is the answer most of the time.
    await tester.tap(find.text('Log it'));
    await tester.pumpAndSettle();

    final task = (await repo.watchTasks().first).single;
    expect(task.jira?.key, 'AT-4496');
    expect(task.minutesOn(todayKey()), 60);
    expect(find.text('Needs one'), findsNothing, reason: 'it is tagged now');
  });

  testWidgets('the picker walks with arrow keys and picks with enter',
      (tester) async {
    configureSize(tester, GoldenSize.mac);
    final repo = SeedlingRepo(FakeFirebaseFirestore(), 'bas');
    await repo.addTask('Needs one', date: todayKey());
    await repo.rememberJiraTickets([
      const JiraTicket(key: 'AT-1', site: _site, summary: 'Older'),
      const JiraTicket(key: 'ZZ-9', site: _site, summary: 'Zebra'),
    ]);

    await tester.pumpWidget(wrapApp(_screen(repo)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Needs one'));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.tap(find.text('No time'));
    await tester.pumpAndSettle();

    final task = (await repo.watchTasks().first).single;
    expect(task.jira?.key, 'ZZ-9', reason: 'one step down is the second row');
  });

  testWidgets('a ticket just used sorts to the top next time', (tester) async {
    configureSize(tester, GoldenSize.mac);
    final repo = SeedlingRepo(FakeFirebaseFirestore(), 'bas');
    await repo.addTask('Needs one', date: todayKey());
    await repo.rememberJiraTickets([
      const JiraTicket(key: 'AT-1', site: _site, summary: 'Older'),
      const JiraTicket(key: 'ZZ-9', site: _site, summary: 'Zebra'),
    ]);

    await tester.pumpWidget(wrapApp(_screen(repo)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Needs one'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zebra'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('No time'));
    await tester.pumpAndSettle();

    expect((await repo.watchJiraTickets().first).first.key, 'ZZ-9');
  });

  testWidgets('declining the time still leaves the ticket attached',
      (tester) async {
    configureSize(tester, GoldenSize.mac);
    final repo = SeedlingRepo(FakeFirebaseFirestore(), 'bas');
    await repo.addTask('Needs one', date: todayKey());
    await repo.rememberJiraTickets(
        [const JiraTicket(key: 'AT-1', site: _site, summary: 'Older')]);

    await tester.pumpWidget(wrapApp(_screen(repo)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Needs one'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Older'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('No time'));
    await tester.pumpAndSettle();

    final task = (await repo.watchTasks().first).single;
    expect(task.jira?.key, 'AT-1');
    expect(task.totalMinutes, 0);
  });

  testWidgets('the day arrows move a day at a time', (tester) async {
    configureSize(tester, GoldenSize.mac);
    final moves = <int>[];
    await tester.pumpWidget(wrapApp(TurboTaggerView(
      dayKey: '2026-07-28',
      tasks: const [],
      onDay: moves.add,
    )));

    await tester.tap(find.byTooltip('The day before'));
    await tester.tap(find.byTooltip('The day after'));

    expect(moves, [-1, 1]);
  });

  group('tickets you already used', () {
    testWidgets('are in the list without pasting anything', (tester) async {
      configureSize(tester, GoldenSize.mac);
      final repo = SeedlingRepo(FakeFirebaseFirestore(), 'bas');
      // Tagged some time ago, on a day that is not today.
      await repo.addTask('Old work', date: '2026-07-01');
      final old = (await repo.watchTasks().first).single;
      await repo.setJira(old, const JiraRef(key: 'MAF-4319', site: _site));
      await repo.addTask('Needs one', date: todayKey());

      await tester.pumpWidget(wrapApp(_screen(repo,
          jira: MockClient((_) async => http.Response('{"issues":[]}', 200)))));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Needs one'));
      await tester.pumpAndSettle();

      // Unnamed, so it shows as its key in both the label and the title.
      expect(find.text('MAF-4319'), findsWidgets);
    });

    testWidgets('get their names looked up on opening', (tester) async {
      configureSize(tester, GoldenSize.mac);
      final repo = SeedlingRepo(FakeFirebaseFirestore(), 'bas');
      await repo.addTask('Old work', date: '2026-07-01');
      final old = (await repo.watchTasks().first).single;
      await repo.setJira(old, const JiraRef(key: 'MAF-4319', site: _site));

      final jira = MockClient((_) async => http.Response(
            jsonEncode({
              'issues': [
                {'key': 'MAF-4319', 'fields': {'summary': 'Meetings, testing'}}
              ]
            }),
            200,
          ));

      await tester.pumpWidget(wrapApp(_screen(repo, jira: jira)));
      await tester.pumpAndSettle();

      final stored = await repo.watchJiraTickets().first;
      expect(stored.single.summary, 'Meetings, testing');
    });

    testWidgets('without a Jira account they still appear, just unnamed',
        (tester) async {
      configureSize(tester, GoldenSize.mac);
      final repo = SeedlingRepo(FakeFirebaseFirestore(), 'bas');
      await repo.addTask('Old work', date: '2026-07-01');
      final old = (await repo.watchTasks().first).single;
      await repo.setJira(old, const JiraRef(key: 'AT-9', site: _site));

      await tester.pumpWidget(wrapApp(_screen(repo, account: false)));
      await tester.pumpAndSettle();

      expect((await repo.watchJiraTickets().first).single.key, 'AT-9');
    });
  });
}
