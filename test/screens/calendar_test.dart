import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/data/calendar_source.dart';
import 'package:seedling/data/seedling_repo.dart';
import 'package:seedling/logic/day_key.dart';
import 'package:seedling/models/calendar_event.dart';
import 'package:seedling/screens/day_page.dart';
import 'package:seedling/widgets/timed_block.dart';

import '../util/golden/golden_utils.dart';

CalendarEvent _event(
  String title, {
  required String day,
  String? time,
  bool allDay = false,
  String? recurringId,
}) =>
    CalendarEvent(
      id: '$title-$day',
      title: title,
      dayKey: day,
      allDay: allDay,
      time: time,
      recurringId: recurringId,
    );

void main() {
  const day = '2026-07-15';

  goldenForSizes(
    'timed block with appointments',
    'timed_with_events',
    [GoldenSize.phone],
    () => Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: TimedBlock(
            tasks: const [],
            tags: const {},
            shownDay: day,
            onToggle: (_) {},
            onMenu: (_) {},
            events: [
              _event("Joan's birthday", day: day, allDay: true),
              _event('Vet appointment', day: day, time: '09:00'),
              _event('Bins out', day: day, time: '19:00'),
            ],
          ),
        ),
      ),
    ),
  );

  testWidgets('an all-day event says so instead of showing a time',
      (tester) async {
    await tester.pumpWidget(wrapApp(Scaffold(
      body: TimedBlock(
        tasks: const [],
        tags: const {},
        shownDay: day,
        onToggle: (_) {},
        onMenu: (_) {},
        events: [_event("Joan's birthday", day: day, allDay: true)],
      ),
    )));

    expect(find.text('All day'), findsOneWidget);
  });

  testWidgets('long-pressing an event opens its menu rather than hiding it',
      (tester) async {
    final menus = <String>[];
    await tester.pumpWidget(wrapApp(Scaffold(
      body: TimedBlock(
        tasks: const [],
        tags: const {},
        shownDay: day,
        onToggle: (_) {},
        onMenu: (_) {},
        events: [_event('Bins out', day: day, time: '19:00')],
        onEventMenu: (e) => menus.add(e.hideKey),
      ),
    )));

    await tester.longPress(find.text('Bins out'));

    expect(menus, ['Bins out'],
        reason: 'hiding outright on a long press had nothing to undo it');
  });

  testWidgets('right-clicking an event opens the same menu', (tester) async {
    final menus = <String>[];
    await tester.pumpWidget(wrapApp(Scaffold(
      body: TimedBlock(
        tasks: const [],
        tags: const {},
        shownDay: day,
        onToggle: (_) {},
        onMenu: (_) {},
        events: [_event('Bins out', day: day, time: '19:00')],
        onEventMenu: (e) => menus.add(e.hideKey),
      ),
    )));

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Bins out')),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await gesture.up();
    await tester.pump();

    expect(menus, ['Bins out'], reason: 'right click is the desktop gesture');
  });

  testWidgets('a revealed hidden event offers to come back', (tester) async {
    final restored = <String>[];
    await tester.pumpWidget(wrapApp(Scaffold(
      body: TimedBlock(
        tasks: const [],
        tags: const {},
        shownDay: day,
        onToggle: (_) {},
        onMenu: (_) {},
        events: [_event('Bins out', day: day, time: '19:00')],
        hiddenKeys: const {'Bins out'},
        onUnhideEvent: (e) => restored.add(e.hideKey),
      ),
    )));

    expect(find.text('hidden'), findsNothing);
    expect(find.textContaining('hidden'), findsOneWidget);

    await tester.tap(find.byTooltip('Show this again'));

    expect(restored, ['Bins out']);
  });


  // Only one DayPage test lives in this file: a second one never settles in the
  // same process, so hiding is covered by the TimedBlock test above and by
  // test/data/blacklist_repo_test.dart instead.
  testWidgets('appointments show up on the day page beside the tasks',
      (tester) async {
    configureSize(tester, GoldenSize.phone);
    final repo = SeedlingRepo(FakeFirebaseFirestore(), 'bas');
    final calendar = FakeCalendar([
      _event('Vet appointment', day: todayKey(), time: '09:00'),
      _event('Far future thing', day: addDays(todayKey(), 400), time: '09:00'),
    ]);

    await tester.pumpWidget(wrapApp(DayPage(repo: repo, calendar: calendar)));
    await tester.pumpAndSettle();

    expect(find.text('Vet appointment'), findsOneWidget);
    // Outside the loaded window, so never read.
    expect(find.text('Far future thing'), findsNothing);
  });
}
