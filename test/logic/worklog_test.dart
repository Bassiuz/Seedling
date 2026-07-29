import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/logic/jira_ref.dart';
import 'package:seedling/logic/worklog.dart';
import 'package:seedling/models/event_extras.dart';
import 'package:seedling/models/task.dart';

const _day = '2026-07-28';
const _site = 'https://example.atlassian.net';
const _maf = JiraRef(key: 'MAF-1', site: _site);

Task _task({
  String id = 't',
  JiraRef? jira = _maf,
  Map<String, int> entries = const {_day: 90},
}) =>
    Task(
      id: id,
      title: 'Fix the export',
      date: _day,
      createdDate: _day,
      jira: jira,
      timeEntries: entries,
    );

List<WorklogAction> actions({
  List<Task> tasks = const [],
  Map<String, EventExtras> events = const {},
  Map<String, SentWorklog> sent = const {},
}) =>
    worklogActions(tasks: tasks, events: events, sent: sent);

void main() {
  test('time on a ticket that was never sent is a new worklog', () {
    final result = actions(tasks: [_task()]);

    expect(result, hasLength(1));
    expect(result.single.verb, WorklogVerb.create);
    expect(result.single.jira.key, 'MAF-1');
    expect(result.single.minutes, 90);
    expect(result.single.dayKey, _day);
  });

  test('time on a task with no ticket has nowhere to go', () {
    expect(actions(tasks: [_task(jira: null)]), isEmpty);
  });

  test('a day already sent unchanged is left alone', () {
    // The whole point: pressing send twice must not log the hour twice.
    final result = actions(
      tasks: [_task()],
      sent: {worklogKey('t', _day): const SentWorklog(id: '9', minutes: 90)},
    );

    expect(result, isEmpty);
  });

  test('a corrected number updates the worklog that is there', () {
    final result = actions(
      tasks: [_task(entries: const {_day: 120})],
      sent: {worklogKey('t', _day): const SentWorklog(id: '9', minutes: 90)},
    );

    expect(result.single.verb, WorklogVerb.update);
    expect(result.single.minutes, 120);
    expect(result.single.sentId, '9');
  });

  test('time taken back to nothing removes what was sent', () {
    // Logging it here and then deciding you had not done it must not leave
    // the hour sitting in the timesheet.
    final result = actions(
      tasks: [_task(entries: const {})],
      sent: {worklogKey('t', _day): const SentWorklog(id: '9', minutes: 90)},
    );

    expect(result.single.verb, WorklogVerb.delete);
    expect(result.single.sentId, '9');
    expect(result.single.minutes, 0);
  });

  test('another task on the same day is its own worklog', () {
    final result = actions(tasks: [
      _task(),
      _task(id: 'u', entries: const {_day: 30}),
    ]);

    expect(result, hasLength(2));
    expect(result.map((a) => a.key).toSet(),
        {worklogKey('t', _day), worklogKey('u', _day)});
  });

  test('a task logged across several days is one worklog per day', () {
    final result = actions(tasks: [
      _task(entries: const {_day: 60, '2026-07-29': 30}),
    ]);

    expect(result.map((a) => a.dayKey), [_day, '2026-07-29']);
  });

  test('a tagged meeting is exported like anything else', () {
    final result = actions(events: {
      'standup': const EventExtras(jira: _maf, title: 'Sprint planning')
          .withMinutes(_day, 45),
    });

    expect(result.single.minutes, 45);
    expect(result.single.title, 'Sprint planning');
  });

  test('a meeting with no title falls back to its key', () {
    final result = actions(events: {
      'standup': const EventExtras(jira: _maf).withMinutes(_day, 45),
    });

    expect(result.single.title, 'standup');
  });

  test('a sent day whose source went away is still cleaned up', () {
    // The task was deleted after its time went to Jira.
    final result = actions(
      tasks: [_task(id: 't', entries: const {})],
      sent: {worklogKey('t', _day): const SentWorklog(id: '9', minutes: 90)},
    );

    expect(result.single.verb, WorklogVerb.delete);
  });

  test('sent days belonging to another task are not confused for this one', () {
    // The keys share a prefix; a sloppy startsWith would take "task-10"'s
    // days for "task-1"'s.
    final result = actions(
      tasks: [_task(id: 'task-1', entries: const {_day: 90})],
      sent: {
        worklogKey('task-1', _day): const SentWorklog(id: '9', minutes: 90),
        worklogKey('task-10', _day): const SentWorklog(id: '8', minutes: 30),
      },
    );

    expect(result, isEmpty);
  });

  test('the oldest day comes first', () {
    final result = actions(tasks: [
      _task(id: 'a', entries: const {'2026-07-30': 30}),
      _task(id: 'b', entries: const {'2026-07-28': 30}),
    ]);

    expect(result.map((a) => a.dayKey), ['2026-07-28', '2026-07-30']);
  });
}
