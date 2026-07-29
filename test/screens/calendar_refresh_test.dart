import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/data/calendar_source.dart';
import 'package:seedling/data/seedling_repo.dart';
import 'package:seedling/logic/day_key.dart';
import 'package:seedling/models/calendar_event.dart';
import 'package:seedling/screens/day_page.dart';

import '../util/golden/golden_utils.dart';

CalendarEvent _event(String title, {String? day, String time = '09:00'}) =>
    CalendarEvent(
      id: title,
      title: title,
      dayKey: day ?? todayKey(),
      allDay: false,
      time: time,
    );

/// A calendar whose contents can change between reads, like a real one.
class _MutableCalendar implements CalendarSource {
  _MutableCalendar(this.events);

  List<CalendarEvent> events;
  int reads = 0;

  @override
  Future<bool> get available async => true;

  @override
  bool get worthSharing => true;

  @override
  Future<List<CalendarEvent>> eventsBetween(String from, String to) async {
    reads++;
    return events
        .where((e) =>
            e.dayKey.compareTo(from) >= 0 && e.dayKey.compareTo(to) <= 0)
        .toList();
  }
}

void main() {
  // Appointments used to be read once at startup, so a meeting moved on
  // another device stayed on the day it used to be on until a restart.
  testWidgets('coming back to the app picks up a moved meeting',
      (tester) async {
    final repo = SeedlingRepo(FakeFirebaseFirestore(), 'bas');
    final calendar = _MutableCalendar([_event('Sprint planning')]);

    await tester.pumpWidget(wrapApp(DayPage(repo: repo, calendar: calendar)));
    await tester.pumpAndSettle();
    expect(find.text('Sprint planning'), findsOneWidget);

    calendar.events = [
      _event('Sprint planning', day: addDays(todayKey(), 1), time: '14:00'),
    ];
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.text('Sprint planning'), findsNothing,
        reason: 'it moved to tomorrow');
    expect(calendar.reads, greaterThan(1));
  });
}
