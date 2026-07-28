import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/widgets/day_header.dart';

import '../util/golden/golden_utils.dart';
import '../util/shortcut_finder.dart';

Widget _header({required String dayKey, void Function(int)? onJump}) => Scaffold(
      body: SafeArea(
        child: DayHeader(
          dayKey: dayKey,
          today: '2026-07-15',
          onJump: onJump ?? (_) {},
        ),
      ),
    );

void main() {
  testWidgets('long-pressing the date asks to show hidden events',
      (tester) async {
    var toggles = 0;
    await tester.pumpWidget(wrapApp(Scaffold(
      body: SafeArea(
        child: DayHeader(
          dayKey: '2026-07-15',
          today: '2026-07-15',
          onJump: (_) {},
          onToggleReveal: () => toggles++,
        ),
      ),
    )));

    await tester.longPress(find.text('Wednesday'));

    expect(toggles, 1, reason: 'the phone and BigMe have no keyboard shortcut');
  });

  testWidgets('while revealing, the header says so and how to stop',
      (tester) async {
    await tester.pumpWidget(wrapApp(Scaffold(
      body: SafeArea(
        child: DayHeader(
          dayKey: '2026-07-15',
          today: '2026-07-15',
          onJump: (_) {},
          onToggleReveal: () {},
          revealing: true,
        ),
      ),
    )));

    expect(find.textContaining('Showing hidden events'), findsOneWidget);
  });

  testWidgets('normally there is no reveal notice', (tester) async {
    await tester.pumpWidget(wrapApp(Scaffold(
      body: SafeArea(
        child: DayHeader(
          dayKey: '2026-07-15',
          today: '2026-07-15',
          onJump: (_) {},
        ),
      ),
    )));

    expect(find.textContaining('Showing hidden'), findsNothing);
  });

  goldenForSizes(
    'day header on today',
    'day_header_today',
    [GoldenSize.phone],
    () => _header(dayKey: '2026-07-15'),
  );

  goldenForSizes(
    'day header on a day outside the three shortcuts',
    'day_header_distant',
    [GoldenSize.phone],
    () => _header(dayKey: '2026-06-02'),
  );

  testWidgets('renders the weekday and full date in words', (tester) async {
    await tester.pumpWidget(wrapApp(_header(dayKey: '2026-07-15')));

    expect(find.text('Wednesday'), findsOneWidget);
    expect(find.text('July 15, 2026'), findsOneWidget);
  });

  testWidgets('reports the day it was asked to jump to', (tester) async {
    final jumps = <int>[];
    await tester.pumpWidget(
      wrapApp(_header(dayKey: '2026-07-15', onJump: jumps.add)),
    );

    await tester.tap(find.text('Yesterday'));
    await tester.tap(find.text('Tomorrow'));
    await tester.tap(find.text('Today'));

    expect(jumps, [-1, 1, 0]);
  });

  testWidgets('highlights whichever shortcut matches the shown day',
      (tester) async {
    await tester.pumpWidget(wrapApp(_header(dayKey: '2026-07-16')));
    expect(selectedShortcutLabel(tester), 'Tomorrow');

    await tester.pumpWidget(wrapApp(_header(dayKey: '2026-07-15')));
    expect(selectedShortcutLabel(tester), 'Today');
  });

  testWidgets('highlights nothing on a day beyond the three shortcuts',
      (tester) async {
    await tester.pumpWidget(wrapApp(_header(dayKey: '2026-06-02')));

    expect(selectedShortcutLabel(tester), isNull);
  });
}
