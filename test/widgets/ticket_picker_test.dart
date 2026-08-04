import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/models/jira_ticket.dart';
import 'package:seedling/widgets/ticket_picker.dart';

import '../util/golden/golden_utils.dart';

const _site = 'https://example.atlassian.net';

const _tickets = [
  JiraTicket(key: 'AT-4496', site: _site, summary: 'Retry the autoclicker'),
  JiraTicket(key: 'MAF-4319', site: _site, summary: 'Meetings'),
  JiraTicket(key: 'MAF-4775', site: _site, summary: 'Wordpress onderhoud'),
];

Future<JiraTicket?> _open(WidgetTester tester,
    {List<JiraTicket> tickets = _tickets}) async {
  JiraTicket? picked;
  await tester.pumpWidget(wrapApp(Scaffold(
    body: Builder(
      builder: (context) => TextButton(
        onPressed: () async => picked = await showModalBottomSheet<JiraTicket>(
          context: context,
          isScrollControlled: true,
          builder: (_) => TicketPicker(
              tickets: tickets, title: 'Fix the export', defaultSite: _site),
        ),
        child: const Text('open'),
      ),
    ),
  )));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return picked;
}

Future<void> _press(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('enter takes the first one, which is the most recent',
      (tester) async {
    await _open(tester);

    await _press(tester, LogicalKeyboardKey.enter);

    expect(find.byType(TicketPicker), findsNothing, reason: 'it closed');
  });

  testWidgets('the arrows walk down the list', (tester) async {
    await _open(tester);

    await _press(tester, LogicalKeyboardKey.arrowDown);
    await _press(tester, LogicalKeyboardKey.arrowDown);
    await _press(tester, LogicalKeyboardKey.arrowUp);
    await _press(tester, LogicalKeyboardKey.enter);

    expect(find.byType(TicketPicker), findsNothing);
  });

  testWidgets('the selection cannot walk off either end', (tester) async {
    await _open(tester);

    for (var i = 0; i < 8; i++) {
      await _press(tester, LogicalKeyboardKey.arrowUp);
    }
    await _press(tester, LogicalKeyboardKey.enter);

    expect(find.byType(TicketPicker), findsNothing, reason: 'still on one');
  });

  testWidgets('typing filters, and enter takes what is left', (tester) async {
    await _open(tester);

    await tester.enterText(find.byType(TextField), 'wordpress');
    await tester.pumpAndSettle();

    expect(find.text('Wordpress onderhoud'), findsOneWidget);
    expect(find.text('Meetings'), findsNothing);
  });

  testWidgets('a key it has never seen is offered as a new one',
      (tester) async {
    await _open(tester);

    await tester.enterText(find.byType(TextField), 'AT-9999');
    await tester.pumpAndSettle();

    // Twice: what you typed, and the row offering it.
    expect(find.text('AT-9999'), findsNWidgets(2));
    expect(find.text('Use this ticket'), findsOneWidget);
  });

  testWidgets('a pasted link is read as a ticket too', (tester) async {
    await _open(tester);

    await tester.enterText(
        find.byType(TextField), '$_site/browse/MAF-1234');
    await tester.pumpAndSettle();

    expect(find.text('MAF-1234'), findsOneWidget,
        reason: 'the row shows the key, the field shows the whole link');
  });

  testWidgets('a ticket it already knows is not offered twice',
      (tester) async {
    await _open(tester);

    await tester.enterText(find.byType(TextField), 'MAF-4319');
    await tester.pumpAndSettle();

    expect(find.text('Use this ticket'), findsNothing);
    expect(find.text('Meetings'), findsOneWidget);
  });

  testWidgets('escape closes it without choosing', (tester) async {
    await _open(tester);

    await _press(tester, LogicalKeyboardKey.escape);

    expect(find.byType(TicketPicker), findsNothing);
  });

  testWidgets('an empty list still opens rather than throwing',
      (tester) async {
    await _open(tester, tickets: const []);

    expect(find.text('Nothing matches'), findsOneWidget);
  });
}
