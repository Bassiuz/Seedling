import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/logic/jira_ref.dart';
import 'package:seedling/logic/jira_usage.dart';
import 'package:seedling/models/event_extras.dart';
import 'package:seedling/models/task.dart';
import 'package:seedling/models/topic.dart';

const _site = 'https://example.atlassian.net';
const _at = JiraRef(key: 'AT-1', site: _site);
const _maf = JiraRef(key: 'MAF-2', site: _site);

Task _task({
  String id = 't',
  JiraRef? jira = _at,
  String date = '2026-07-20',
  String? done,
  Map<String, int> entries = const {},
}) =>
    Task(
      id: id,
      title: id,
      date: date,
      createdDate: date,
      jira: jira,
      completedOnDate: done,
      timeEntries: entries,
    );

void main() {
  test('a ticket used on a task is remembered', () {
    final found = ticketsInUse(tasks: [_task()]);

    expect(found.single.key, 'AT-1');
    expect(found.single.site, _site);
  });

  test('a task with no ticket contributes nothing', () {
    expect(ticketsInUse(tasks: [_task(jira: null)]), isEmpty);
  });

  test('recency is the latest day the ticket was actually touched', () {
    // Planned on the 20th, still being worked on the 27th.
    final found = ticketsInUse(tasks: [
      _task(entries: const {'2026-07-27': 60}),
    ]);

    expect(found.single.lastUsed, DateTime(2026, 7, 27));
  });

  test('being finished counts as touching it', () {
    final found = ticketsInUse(tasks: [_task(done: '2026-07-25')]);

    expect(found.single.lastUsed, DateTime(2026, 7, 25));
  });

  test('the same ticket on two tasks keeps the later day', () {
    final found = ticketsInUse(tasks: [
      _task(id: 'a', date: '2026-07-01'),
      _task(id: 'b', date: '2026-07-29'),
    ]);

    expect(found, hasLength(1));
    expect(found.single.lastUsed, DateTime(2026, 7, 29));
  });

  test('most recent first, so the list opens on what you are working on', () {
    final found = ticketsInUse(tasks: [
      _task(id: 'old', jira: _at, date: '2026-07-01'),
      _task(id: 'new', jira: _maf, date: '2026-07-29'),
    ]);

    expect(found.map((t) => t.key), ['MAF-2', 'AT-1']);
  });

  test('tickets on standing topics count too', () {
    final found = ticketsInUse(tasks: const [], topics: [
      const Topic(
          id: 'meetings',
          title: 'Meetings',
          jira: _maf,
          minutes: {'2026-07-28': 120}),
    ]);

    expect(found.single.key, 'MAF-2');
  });

  test('so do tickets on appointments', () {
    final found = ticketsInUse(tasks: const [], events: {
      'standup': const EventExtras(jira: _maf).withMinutes('2026-07-28', 30),
    });

    expect(found.single.key, 'MAF-2');
  });

  test('a topic that has never been logged against has no day to sort by', () {
    // Nothing to date it, so it is left out rather than dated wrongly.
    expect(
      ticketsInUse(
          tasks: const [],
          topics: [const Topic(id: 'm', title: 'Meetings', jira: _maf)]),
      isEmpty,
    );
  });

  group('inBatches', () {
    test('leaves a short list alone', () {
      expect(inBatches(['a', 'b']), [
        ['a', 'b']
      ]);
    });

    test('splits a long one and loses nothing', () {
      final keys = [for (var i = 0; i < 125; i++) 'AT-$i'];
      final batches = inBatches(keys);

      expect(batches.map((b) => b.length), [50, 50, 25]);
      expect(batches.expand((b) => b), keys);
    });

    test('nothing in, nothing out', () {
      expect(inBatches([]), isEmpty);
    });
  });
}
