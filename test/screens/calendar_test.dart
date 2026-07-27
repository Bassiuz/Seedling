import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
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

  testWidgets('long-pressing an event asks to hide it', (tester) async {
    final hidden = <String>[];
    await tester.pumpWidget(wrapApp(Scaffold(
      body: TimedBlock(
        tasks: const [],
        tags: const {},
        shownDay: day,
        onToggle: (_) {},
        onMenu: (_) {},
        events: [_event('Bins out', day: day, time: '19:00')],
        onHideEvent: (e) => hidden.add(e.hideKey),
      ),
    )));

    await tester.longPress(find.text('Bins out'));

    expect(hidden, ['Bins out']);
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
        revealing: true,
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
