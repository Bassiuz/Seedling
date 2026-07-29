import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/logic/jira_ref.dart';
import 'package:seedling/logic/timesheet.dart';
import 'package:seedling/models/task.dart';
import 'package:seedling/models/topic.dart';

const _monday = '2026-07-27';
const _wednesday = '2026-07-29';
const _site = 'https://medappnl.atlassian.net';
const _maf = JiraRef(key: 'MAF-1', site: _site);

Task _task({
  String id = 't',
  String title = 'Retry voor Autoclicker',
  JiraRef? jira = _maf,
  String date = _monday,
  String? done,
  Map<String, int> entries = const {},
}) =>
    Task(
      id: id,
      title: title,
      date: date,
      createdDate: date,
      jira: jira,
      completedOnDate: done,
      timeEntries: entries,
    );

void main() {
  group('weekDays', () {
    test('runs Monday to Sunday whichever day you ask about', () {
      expect(weekDays(_wednesday).first, _monday);
      expect(weekDays(_wednesday).last, '2026-08-02');
      expect(weekDays(_wednesday), hasLength(7));
    });

    test('a Sunday belongs to the week it ends', () {
      expect(weekDays('2026-08-02').first, _monday);
    });
  });

  group('task rows', () {
    test('time logged in the week earns a row, in the right column', () {
      final rows = taskRows(
          [_task(date: '2026-01-01', entries: const {_wednesday: 90})],
          _monday);

      expect(rows.single.minutes, [0, 0, 90, 0, 0, 0, 0]);
      expect(rows.single.total, 90);
    });

    test('a task planned this week gets an empty row to fill in', () {
      // Without the row there is nowhere to type the hours.
      expect(taskRows([_task()], _monday), hasLength(1));
    });

    test('a task checked off this week counts even if planned earlier', () {
      final rows = taskRows(
          [_task(date: '2026-06-01', done: _wednesday)], _monday);

      expect(rows, hasLength(1));
    });

    test('a task with no ticket is not on the sheet', () {
      expect(taskRows([_task(jira: null)], _monday), isEmpty);
    });

    test('a task from another week entirely is left out', () {
      expect(taskRows([_task(date: '2026-01-01')], _monday), isEmpty);
    });

    test('rows read alphabetically, so the sheet does not reshuffle', () {
      final rows = taskRows([
        _task(id: 'b', title: 'Zebra'),
        _task(id: 'a', title: 'Aardvark'),
      ], _monday);

      expect(rows.map((r) => r.title), ['Aardvark', 'Zebra']);
    });
  });

  group('topic rows', () {
    test('a standing row is always there, empty or not', () {
      final rows = topicRows(
          [const Topic(id: 'm', title: 'Meetings')], _monday);

      expect(rows.single.minutes, [0, 0, 0, 0, 0, 0, 0]);
    });

    test('its hours land on the right day', () {
      final rows = topicRows([
        const Topic(id: 'm', title: 'Meetings', minutes: {_wednesday: 120}),
      ], _monday);

      expect(rows.single.minutes[2], 120);
    });

    test('it carries the topic, so the row can be edited or removed', () {
      final rows =
          topicRows([const Topic(id: 'm', title: 'Meetings')], _monday);

      expect(rows.single.topic?.id, 'm');
    });
  });

  test('the day totals add both grids together', () {
    final totals = dayTotals([
      ...taskRows([_task(entries: const {_monday: 60})], _monday),
      ...topicRows([
        const Topic(id: 'm', title: 'Meetings', minutes: {_monday: 30}),
      ], _monday),
    ]);

    expect(totals.first, 90);
    expect(totals.skip(1), everyElement(0));
  });
}
