import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/data/seedling_repo.dart';
import 'package:seedling/logic/jira_ref.dart';
import 'package:seedling/models/event_extras.dart';

const _day = '2026-07-28';

void main() {
  late SeedlingRepo repo;

  setUp(() => repo = SeedlingRepo(FakeFirebaseFirestore(), 'bas'));

  test('an untouched event has nothing on it', () async {
    expect(await repo.watchEventExtras().first, isEmpty);
  });

  test('a tag, a ticket and logged time all survive the round trip', () async {
    await repo.setEventExtras(
      'standup',
      const EventExtras(
        tagId: 'moxify',
        jira: JiraRef(key: 'MAF-1', site: 'https://m.atlassian.net'),
      ).withMinutes(_day, 30),
    );

    final stored = (await repo.watchEventExtras().first)['standup']!;
    expect(stored.tagId, 'moxify');
    expect(stored.jira?.key, 'MAF-1');
    expect(stored.minutesOn(_day), 30);
  });

  test('an id the calendar gave us is stored under a key Firestore accepts',
      () async {
    // EventKit ids contain slashes, which are path separators to Firestore.
    await repo.setEventExtras(
        'ABC/DEF:1', const EventExtras(tagId: 'health'));

    final stored = await repo.watchEventExtras().first;
    expect(stored['ABC/DEF:1']?.tagId, 'health');
  });

  test('time is logged per day, not per series', () async {
    await repo.setEventExtras(
        'standup', const EventExtras().withMinutes(_day, 15));
    final stored = (await repo.watchEventExtras().first)['standup']!;

    expect(stored.minutesOn(_day), 15);
    expect(stored.minutesOn('2026-07-29'), 0);
  });

  test('clearing the last thing on an event forgets it entirely', () async {
    await repo.setEventExtras('standup', const EventExtras(tagId: 'moxify'));
    await repo.setEventExtras('standup', const EventExtras());

    expect(await repo.watchEventExtras().first, isEmpty);
  });

  test('zero minutes drops the day rather than storing nothing', () {
    final extras = const EventExtras().withMinutes(_day, 45);
    expect(extras.withMinutes(_day, 0).minutes, isEmpty);
    expect(extras.totalMinutes, 45);
  });
}
