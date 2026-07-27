import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/widgets/day_header.dart';

import '../util/golden/golden_utils.dart';

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

/// The label of the shortcut currently drawn as selected, or null if none is.
String? selectedShortcutLabel(WidgetTester tester) {
  for (final label in ['Yesterday', 'Today', 'Tomorrow']) {
    final finder = find.ancestor(
      of: find.text(label),
      matching: find.byType(DayShortcut),
    );
    if (tester.widget<DayShortcut>(finder).selected) return label;
  }
  return null;
}
