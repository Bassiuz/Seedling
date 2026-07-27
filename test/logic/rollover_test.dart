import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/logic/rollover.dart';
import 'package:seedling/models/task.dart';

const tuesday = '2026-07-21';
const wednesday = '2026-07-22';
const thursday = '2026-07-23';
const friday = '2026-07-24';

Task task({
  String id = 'a',
  String title = 'Afwas doen',
  required String date,
  String? createdDate,
  String? time,
  String? completedOnDate,
}) =>
    Task(
      id: id,
      title: title,
      date: date,
      createdDate: createdDate ?? date,
      time: time,
      completedOnDate: completedOnDate,
    );

void main() {
  // The scenario Bas described in his own words: a task planned Tuesday, and
  // on Thursday he pages back to Wednesday and ticks it off there.
  group("checked off on Wednesday's page while it is Thursday", () {
    final t = task(date: tuesday, completedOnDate: wednesday);
    const today = thursday;

    test('is still visible on Tuesday, shown as done later', () {
      expect(taskVisibleOn(t, tuesday, today), isTrue);
      expect(checkStateOn(t, tuesday), TaskCheckState.doneLater);
    });

    test('is visible on Wednesday, shown as checked there', () {
      expect(taskVisibleOn(t, wednesday, today), isTrue);
      expect(checkStateOn(t, wednesday), TaskCheckState.checkedHere);
    });

    test('is gone from Thursday entirely', () {
      expect(taskVisibleOn(t, thursday, today), isFalse);
    });
  });

  group('an open task', () {
    final t = task(date: tuesday);

    test('carries forward from its planned day up to today', () {
      expect(taskVisibleOn(t, tuesday, thursday), isTrue);
      expect(taskVisibleOn(t, wednesday, thursday), isTrue);
      expect(taskVisibleOn(t, thursday, thursday), isTrue);
    });

    test('does not project into the future', () {
      expect(taskVisibleOn(t, friday, thursday), isFalse);
    });

    test('reads as open on every day it appears', () {
      expect(checkStateOn(t, tuesday), TaskCheckState.open);
      expect(checkStateOn(t, thursday), TaskCheckState.open);
    });
  });

  group('other cases', () {
    test('a future-planned task appears only on its own day', () {
      final t = task(date: friday);
      expect(taskVisibleOn(t, thursday, thursday), isFalse);
      expect(taskVisibleOn(t, friday, thursday), isTrue);
    });

    test('a snoozed task leaves today and appears on its new date', () {
      final snoozed = task(date: tuesday).copyWith(date: friday);
      expect(taskVisibleOn(snoozed, thursday, thursday), isFalse);
      expect(taskVisibleOn(snoozed, friday, thursday), isTrue);
    });

    test('a task planned and completed today shows only today', () {
      final t = task(date: thursday, completedOnDate: thursday);
      expect(taskVisibleOn(t, thursday, thursday), isTrue);
      expect(checkStateOn(t, thursday), TaskCheckState.checkedHere);
      expect(taskVisibleOn(t, friday, thursday), isFalse);
    });

    test('completing today a task planned earlier keeps it on both days', () {
      final t = task(date: tuesday, completedOnDate: thursday);
      expect(taskVisibleOn(t, tuesday, thursday), isTrue);
      expect(taskVisibleOn(t, wednesday, thursday), isTrue);
      expect(taskVisibleOn(t, thursday, thursday), isTrue);
      expect(checkStateOn(t, thursday), TaskCheckState.checkedHere);
    });

    test('completedOnDate before the planned date grants no extra visibility',
        () {
      final anomaly = task(date: thursday, completedOnDate: tuesday);
      expect(taskVisibleOn(anomaly, thursday, thursday), isTrue);
      expect(taskVisibleOn(anomaly, tuesday, thursday), isFalse);
      expect(taskVisibleOn(anomaly, wednesday, thursday), isFalse);
    });
  });

  group('tasksForDay', () {
    test('puts timed tasks first by time, then untimed by createdDate', () {
      final all = [
        task(id: 'untimed-late', date: thursday, createdDate: wednesday),
        task(id: 'timed-evening', date: thursday, time: '18:00'),
        task(id: 'untimed-early', date: thursday, createdDate: tuesday),
        task(id: 'timed-morning', date: thursday, time: '09:00'),
      ];
      expect(
        tasksForDay(all, thursday, thursday).map((t) => t.id).toList(),
        ['timed-morning', 'timed-evening', 'untimed-early', 'untimed-late'],
      );
    });

    test('drops tasks that are not visible on the day', () {
      final all = [
        task(id: 'shown', date: thursday),
        task(id: 'future', date: friday),
        task(id: 'done-yesterday', date: tuesday, completedOnDate: wednesday),
      ];
      expect(
        tasksForDay(all, thursday, thursday).map((t) => t.id).toList(),
        ['shown'],
      );
    });

    test('returns an empty list for a day with nothing on it', () {
      expect(tasksForDay(const [], thursday, thursday), isEmpty);
    });

    test('does not modify the list it was given', () {
      final all = [
        task(id: 'b', date: thursday, time: '18:00'),
        task(id: 'a', date: thursday, time: '09:00'),
      ];
      tasksForDay(all, thursday, thursday);
      expect(all.map((t) => t.id).toList(), ['b', 'a']);
    });
  });
}
