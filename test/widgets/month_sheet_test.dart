import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/widgets/month_sheet.dart';

import '../util/golden/golden_utils.dart';

const _today = '2026-07-28';
const _active = {'2026-07-01', '2026-07-02', '2026-07-06', '2026-07-27',
    '2026-07-28'};

Widget _month({void Function(String)? onPick}) => Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: MonthView(
            month: _today,
            selected: _today,
            today: _today,
            activeDays: _active,
            onPick: onPick ?? (_) {},
          ),
        ),
      ),
    );

void main() {
  goldenForSizes(
    'month view with the days you did something on filled in',
    'month_view',
    [GoldenSize.phone, GoldenSize.eink],
    _month,
  );

  testWidgets('tapping a day hands it back', (tester) async {
    final picked = <String>[];
    await tester.pumpWidget(wrapApp(_month(onPick: picked.add)));

    await tester.tap(find.text('14'));

    expect(picked, ['2026-07-14']);
  });

  testWidgets('the blanks around the month are not tappable', (tester) async {
    final picked = <String>[];
    await tester.pumpWidget(wrapApp(_month(onPick: picked.add)));

    // July 2026 starts on a Wednesday: the first two cells are empty.
    expect(find.text('1'), findsOneWidget);
    expect(picked, isEmpty);
  });

  testWidgets('swiping the sheet moves to the next month', (tester) async {
    await tester.pumpWidget(wrapApp(Scaffold(
      body: MonthSheet(selected: _today, today: _today, onPick: (_) {}),
    )));
    await tester.pumpAndSettle();

    expect(find.text('July 2026'), findsOneWidget);

    await tester.drag(find.text('July 2026'), const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(find.text('August 2026'), findsOneWidget);
  });
}
