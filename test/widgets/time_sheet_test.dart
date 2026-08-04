import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/models/task.dart';
import 'package:seedling/widgets/time_sheet.dart';

import '../util/golden/golden_utils.dart';

const _day = '2026-07-27';

Task _task({Map<String, int> entries = const {}}) => Task(
      id: 't',
      title: 'Fix the launch trailer',
      date: _day,
      createdDate: _day,
      timeEntries: entries,
    );

Widget _sheet(Task task,
        {void Function(int)? onChange,
        void Function(int)? onSet,
        bool autofocus = false}) =>
    Scaffold(
      body: TimeSheet(
        title: task.title,
        minutes: task.minutesOn(_day),
        totalMinutes: task.totalMinutes,
        onChange: onChange ?? (_) {},
        onSet: onSet,
        autofocus: autofocus,
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

  testWidgets('a typed duration sets the day outright', (tester) async {
    final set = <int>[];
    await tester.pumpWidget(wrapApp(_sheet(_task(), onSet: set.add)));

    await tester.enterText(find.byType(TextField), '3:15');
    await tester.testTextInput.receiveAction(TextInputAction.done);

    expect(set, [195]);
  });

  testWidgets('typing a small number means hours', (tester) async {
    final set = <int>[];
    await tester.pumpWidget(wrapApp(_sheet(_task(), onSet: set.add)));

    await tester.enterText(find.byType(TextField), '3');
    await tester.testTextInput.receiveAction(TextInputAction.done);

    expect(set, [180]);
  });

  testWidgets('typing something unreadable logs nothing', (tester) async {
    final set = <int>[];
    await tester.pumpWidget(wrapApp(_sheet(_task(), onSet: set.add)));

    await tester.enterText(find.byType(TextField), 'soon');
    await tester.testTextInput.receiveAction(TextInputAction.done);

    expect(set, isEmpty);
  });

  testWidgets('without onSet the sheet stays stepper-only', (tester) async {
    await tester.pumpWidget(wrapApp(_sheet(_task())));

    expect(find.byType(TextField), findsNothing);
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

  group('opened by the keyboard', () {
    testWidgets('the cursor is already in the box', (tester) async {
      // Ctrl-T, "2", enter. Having to click the field first is the whole
      // thing the shortcut exists to avoid.
      await tester.pumpWidget(
          wrapApp(_sheet(_task(), onSet: (_) {}, autofocus: true)));
      await tester.pump();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.autofocus, isTrue);
      expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<TextField>(),
        isNotNull,
      );
    });

    testWidgets('typing then enter logs it without touching the mouse',
        (tester) async {
      final set = <int>[];
      await tester.pumpWidget(
          wrapApp(_sheet(_task(), onSet: set.add, autofocus: true)));
      await tester.pump();

      await tester.enterText(find.byType(TextField), '2');
      await tester.testTextInput.receiveAction(TextInputAction.done);

      expect(set, [120]);
    });

    testWidgets('opened by hand it does not steal the keyboard',
        (tester) async {
      await tester.pumpWidget(wrapApp(_sheet(_task(), onSet: (_) {})));
      await tester.pump();

      expect(
          tester.widget<TextField>(find.byType(TextField)).autofocus, isFalse);
    });
  });
}
