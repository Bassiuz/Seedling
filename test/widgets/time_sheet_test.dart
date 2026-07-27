import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/models/task.dart';
import 'package:seedling/widgets/time_sheet.dart';

import '../util/golden/golden_utils.dart';

const _day = '2026-07-27';

Task _task({Map<String, int> entries = const {}}) => Task(
      id: 't',
      title: 'Fix Shipaton promo video',
      date: _day,
      createdDate: _day,
      timeEntries: entries,
    );

Widget _sheet(Task task, {void Function(int)? onChange}) => Scaffold(
      body: TimeSheet(
        task: task,
        dayKey: _day,
        onChange: onChange ?? (_) {},
      ),
    );

void main() {
  goldenForSizes(
    'time sheet',
    'time_sheet',
    [GoldenSize.phone],
    () => _sheet(_task(entries: const {_day: 45, '2026-07-26': 90})),
  );

  group('format', () {
    test('reads as hours and minutes', () {
      expect(TimeSheet.format(0), 'none');
      expect(TimeSheet.format(15), '15m');
      expect(TimeSheet.format(60), '1h');
      expect(TimeSheet.format(90), '1h 30m');
      expect(TimeSheet.format(480), '8h');
    });

    test('treats negatives as nothing logged', () {
      expect(TimeSheet.format(-15), 'none');
    });
  });

  testWidgets('adds a quarter of an hour', (tester) async {
    final deltas = <int>[];
    await tester.pumpWidget(wrapApp(_sheet(_task(), onChange: deltas.add)));

    await tester.tap(find.byTooltip('Another 15 minutes'));

    expect(deltas, [15]);
  });

  testWidgets('cannot subtract below nothing', (tester) async {
    final deltas = <int>[];
    await tester.pumpWidget(wrapApp(_sheet(_task(), onChange: deltas.add)));

    await tester.tap(find.byTooltip('Less 15 minutes'));

    expect(deltas, isEmpty);
  });

  testWidgets('subtracts once there is something logged', (tester) async {
    final deltas = <int>[];
    await tester.pumpWidget(wrapApp(
      _sheet(_task(entries: const {_day: 30}), onChange: deltas.add),
    ));

    await tester.tap(find.byTooltip('Less 15 minutes'));

    expect(deltas, [-15]);
  });

  testWidgets('shows the day and the all-days total separately',
      (tester) async {
    await tester.pumpWidget(wrapApp(
      _sheet(_task(entries: const {_day: 45, '2026-07-26': 90})),
    ));

    expect(find.text('45m'), findsOneWidget);
    expect(find.text('2h 15m across all days'), findsOneWidget);
  });

  testWidgets('hides the all-days line when it would just repeat the day',
      (tester) async {
    await tester.pumpWidget(
      wrapApp(_sheet(_task(entries: const {_day: 45}))),
    );

    expect(find.textContaining('across all days'), findsNothing);
  });
}
