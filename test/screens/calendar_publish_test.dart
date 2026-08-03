import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/data/calendar_source.dart';
import 'package:seedling/data/seedling_repo.dart';
import 'package:seedling/logic/day_key.dart';
import 'package:seedling/models/calendar_event.dart';
import 'package:seedling/screens/day_page.dart';

import '../util/golden/golden_utils.dart';

CalendarEvent _event(String title) => CalendarEvent(
    id: title, title: title, dayKey: todayKey(), allDay: false, time: '09:00');

/// A calendar whose read can be held open, so a rebuild can be slipped in
/// while it is in flight.
class _SlowCalendar implements CalendarSource {
  _SlowCalendar(this.events, {this.gate});

  final List<CalendarEvent> events;
  final Completer<void>? gate;
  bool _readOwn = false;

  @override
  Future<bool> get available async => true;

  @override
  bool get worthSharing => _readOwn;

  @override
  Future<List<CalendarEvent>> eventsBetween(String from, String to) async {
    if (gate != null) await gate!.future;
    _readOwn = events.isNotEmpty;
    return events;
  }
}

void main() {
  testWidgets('a rebuild mid-read does not lose the publish', (tester) async {
    // app.dart builds a fresh calendar source on every rebuild, and whether
    // the read came off this device is state on that instance. Checking it
    // after the await used to read a brand new object, which says no — so a
    // rebuild landing during a slow EventKit read silently skipped the
    // publish and the other devices went stale.
    final repo = SeedlingRepo(FakeFirebaseFirestore(), 'bas');
    final gate = Completer<void>();
    final reading = _SlowCalendar([_event('Standup')], gate: gate);

    await tester.pumpWidget(wrapApp(DayPage(
      repo: repo,
      calendar: reading,
      publishesCalendar: true,
    )));

    // The rebuild: a different instance, which has read nothing.
    await tester.pumpWidget(wrapApp(DayPage(
      repo: repo,
      calendar: _SlowCalendar([_event('Standup')]),
      publishesCalendar: true,
    )));

    gate.complete();
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(await repo.readCalendarMirror(addDays(todayKey(), -1), todayKey()),
        isNotEmpty,
        reason: 'the read that finished is the one worth sharing');
  });

  testWidgets('a device reading the mirror still never publishes',
      (tester) async {
    final repo = SeedlingRepo(FakeFirebaseFirestore(), 'bas');

    await tester.pumpWidget(wrapApp(DayPage(
      repo: repo,
      calendar: MirrorCalendar((_, _) async => [_event('Shared')]),
      publishesCalendar: true,
    )));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(await repo.readCalendarMirror(addDays(todayKey(), -1), todayKey()),
        isEmpty,
        reason: 'republishing a mirror over itself helps nobody');
  });
}
