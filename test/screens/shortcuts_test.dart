import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/data/calendar_source.dart';
import 'package:seedling/data/seedling_repo.dart';
import 'package:seedling/logic/day_key.dart';
import 'package:seedling/widgets/time_sheet.dart';
import 'package:seedling/screens/day_page.dart';

import '../util/golden/golden_utils.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _control(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyDownEvent(key);
  await tester.sendKeyUpEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await _settle(tester);
}

void main() {
  // The shortcuts used to hang off CallbackShortcuts, which only fires while
  // focus is inside it. After a click anywhere it was not, so macOS beeped at
  // a key nothing had handled.
  testWidgets('ctrl-T opens the time sheet on the hovered task',
      (tester) async {
    configureSize(tester, GoldenSize.mac);
    final repo = SeedlingRepo(FakeFirebaseFirestore(), 'bas');
    await repo.addTask('Water the greenhouse', date: todayKey());

    await tester.pumpWidget(
        wrapApp(DayPage(repo: repo, calendar: const NoCalendar())));
    await _settle(tester);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await tester.pump();
    await mouse.moveTo(tester.getCenter(find.text('Water the greenhouse')));
    await _settle(tester);

    await _control(tester, LogicalKeyboardKey.keyT);

    expect(find.byType(TimeSheet), findsOneWidget);
  });

  testWidgets('with nothing hovered it does nothing at all', (tester) async {
    configureSize(tester, GoldenSize.mac);
    final repo = SeedlingRepo(FakeFirebaseFirestore(), 'bas');
    await repo.addTask('Water the greenhouse', date: todayKey());

    await tester.pumpWidget(
        wrapApp(DayPage(repo: repo, calendar: const NoCalendar())));
    await _settle(tester);

    await _control(tester, LogicalKeyboardKey.keyT);

    expect(find.byType(TimeSheet), findsNothing);
  });
}
