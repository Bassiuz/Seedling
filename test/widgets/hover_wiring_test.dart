import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/models/calendar_event.dart';
import 'package:seedling/models/task.dart';
import 'package:seedling/screens/day_page.dart';

import '../util/golden/golden_utils.dart';

const _day = '2026-07-28';

Task _task(String title, {String? time}) => Task(
    id: title, title: title, date: _day, createdDate: _day, time: time);

CalendarEvent _event(String title) => CalendarEvent(
    id: title, title: title, dayKey: _day, allDay: false, time: '10:00');

/// One mouse for the whole test. MouseRegion only answers to a real pointer,
/// and adding a second one for the same device trips an assertion inside the
/// framework's tracker.
Future<TestGesture> _mouse(WidgetTester tester) async {
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: Offset.zero);
  addTearDown(mouse.removePointer);
  await tester.pump();
  return mouse;
}

Future<void> _hoverOver(
    WidgetTester tester, TestGesture mouse, Finder target) async {
  await mouse.moveTo(tester.getCenter(target));
  await tester.pumpAndSettle();
}

Widget _content({
  void Function(Task, bool)? onHoverTask,
  void Function(CalendarEvent, bool)? onHoverEvent,
}) =>
    Scaffold(
      body: DayContent(
        dayKey: _day,
        today: _day,
        tasks: [_task('Untimed one'), _task('Timed one', time: '09:00')],
        tags: const {},
        note: '',
        events: [_event('Standup')],
        onToggle: (_) {},
        onMenu: (_) {},
        onAdd: (_, {tagId, time}) {},
        onNoteChanged: (_) {},
        onHoverTask: onHoverTask,
        onHoverEvent: onHoverEvent,
      ),
    );

void main() {
  // The callbacks were declared on DayContent and never passed to the blocks
  // underneath, so hovering reported nothing and both shortcuts fired at a
  // task that was always null. Nothing failed; it simply did nothing.
  testWidgets('hovering an untimed task reaches the page above',
      (tester) async {
    configureSize(tester, GoldenSize.mac);
    final seen = <(String, bool)>[];
    await tester.pumpWidget(
        wrapApp(_content(onHoverTask: (t, h) => seen.add((t.title, h)))));

    await _hoverOver(tester, await _mouse(tester), find.text('Untimed one'));

    expect(seen, contains(('Untimed one', true)));
  });

  testWidgets('and a timed one does too', (tester) async {
    configureSize(tester, GoldenSize.mac);
    final seen = <(String, bool)>[];
    await tester.pumpWidget(
        wrapApp(_content(onHoverTask: (t, h) => seen.add((t.title, h)))));

    await _hoverOver(tester, await _mouse(tester), find.text('Timed one'));

    expect(seen, contains(('Timed one', true)));
  });

  testWidgets('and so does an appointment', (tester) async {
    configureSize(tester, GoldenSize.mac);
    final seen = <(String, bool)>[];
    await tester.pumpWidget(
        wrapApp(_content(onHoverEvent: (e, h) => seen.add((e.title, h)))));

    await _hoverOver(tester, await _mouse(tester), find.text('Standup'));

    expect(seen, contains(('Standup', true)));
  });

  testWidgets('leaving reports it, so the shortcuts stop pointing at it',
      (tester) async {
    configureSize(tester, GoldenSize.mac);
    final seen = <(String, bool)>[];
    await tester.pumpWidget(
        wrapApp(_content(onHoverTask: (t, h) => seen.add((t.title, h)))));

    final mouse = await _mouse(tester);
    await _hoverOver(tester, mouse, find.text('Untimed one'));
    await _hoverOver(tester, mouse, find.text('Timed one'));

    expect(seen, contains(('Untimed one', false)));
  });
}
