import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/data/seedling_repo.dart';
import 'package:seedling/logic/day_key.dart';
import 'package:seedling/logic/jira_ref.dart';
import 'package:seedling/models/tag.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late SeedlingRepo repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = SeedlingRepo(firestore, 'bas');
  });

  group('tasks', () {
    test('addTask stores it and watchTasks emits it', () async {
      await repo.addTask('Water the greenhouse', date: '2026-07-15', time: '18:00');

      final tasks = await repo.watchTasks().first;
      expect(tasks, hasLength(1));
      expect(tasks.single.title, 'Water the greenhouse');
      expect(tasks.single.date, '2026-07-15');
      expect(tasks.single.time, '18:00');
      expect(tasks.single.tagId, isNull);
    });

    test('addTask stamps createdDate with today', () async {
      await repo.addTask('Edit the onboarding copy', date: '2026-08-01');

      final task = (await repo.watchTasks().first).single;
      expect(task.createdDate, todayKey());
    });

    test('setCompleted records the day, then clears it', () async {
      await repo.addTask('Afwas doen', date: '2026-07-21');
      final task = (await repo.watchTasks().first).single;

      await repo.setCompleted(task, '2026-07-22');
      expect((await repo.watchTasks().first).single.completedOnDate,
          '2026-07-22');

      await repo.setCompleted(task, null);
      expect((await repo.watchTasks().first).single.completedOnDate, isNull);
    });

    test('snooze moves the planned date and leaves createdDate alone',
        () async {
      await repo.addTask('Fix promo video', date: '2026-07-15');
      final task = (await repo.watchTasks().first).single;

      await repo.snooze(task, '2026-07-20');

      final moved = (await repo.watchTasks().first).single;
      expect(moved.date, '2026-07-20');
      expect(moved.createdDate, task.createdDate);
    });

    test('logTime accumulates per day and never goes negative', () async {
      await repo.addTask('Fix promo video', date: '2026-07-27');
      var task = (await repo.watchTasks().first).single;

      await repo.logTime(task, '2026-07-27', 15);
      task = (await repo.watchTasks().first).single;
      await repo.logTime(task, '2026-07-27', 30);
      task = (await repo.watchTasks().first).single;
      expect(task.minutesOn('2026-07-27'), 45);

      await repo.logTime(task, '2026-07-26', 60);
      task = (await repo.watchTasks().first).single;
      expect(task.totalMinutes, 105);

      // Subtracting more than was logged clears the day rather than going below
      // zero.
      await repo.logTime(task, '2026-07-26', -120);
      task = (await repo.watchTasks().first).single;
      expect(task.minutesOn('2026-07-26'), 0);
      expect(task.timeEntries.containsKey('2026-07-26'), isFalse);
    });

    test('a time can be set on an existing task, and taken off again',
        () async {
      await repo.addTask('Fix promo video', date: '2026-07-28');
      var task = (await repo.watchTasks().first).single;
      expect(task.isTimed, isFalse);

      await repo.setTime(task, '17:00');
      task = (await repo.watchTasks().first).single;
      expect(task.time, '17:00');
      expect(task.isTimed, isTrue);

      await repo.setTime(task, null);
      task = (await repo.watchTasks().first).single;
      expect(task.time, isNull, reason: 'back out of the timed list');
    });

    test('a tag can be set on an existing task, and taken off again',
        () async {
      await repo.addTask('Fix promo video', date: '2026-07-28');
      var task = (await repo.watchTasks().first).single;
      expect(task.tagId, isNull);

      await repo.setTag(task, 'moxify');
      task = (await repo.watchTasks().first).single;
      expect(task.tagId, 'moxify');

      await repo.setTag(task, null);
      expect((await repo.watchTasks().first).single.tagId, isNull);
    });

    test('setting a time leaves everything else alone', () async {
      await repo.addTask('Fix promo video',
          date: '2026-07-28', tagId: 'moxify');
      var task = (await repo.watchTasks().first).single;
      await repo.setCompleted(task, '2026-07-28');
      task = (await repo.watchTasks().first).single;

      await repo.setTime(task, '09:00');

      final after = (await repo.watchTasks().first).single;
      expect(after.tagId, 'moxify');
      expect(after.completedOnDate, '2026-07-28');
      expect(after.title, 'Fix promo video');
    });

    test('a Jira ticket can be linked and unlinked', () async {
      await repo.addTask('Fix the login bug', date: '2026-07-28');
      var task = (await repo.watchTasks().first).single;
      expect(task.jira, isNull);

      await repo.setJira(
        task,
        const JiraRef(key: 'MAF-1234', site: 'https://medappnl.atlassian.net'),
      );
      task = (await repo.watchTasks().first).single;
      expect(task.jira!.key, 'MAF-1234');
      expect(task.jira!.url, 'https://medappnl.atlassian.net/browse/MAF-1234');

      await repo.setJira(task, null);
      expect((await repo.watchTasks().first).single.jira, isNull);
    });

    test('the Jira site is remembered so a bare key is enough later',
        () async {
      expect(await repo.watchJiraSite().first, isNull);

      await repo.rememberJiraSite('https://medappnl.atlassian.net');

      expect(await repo.watchJiraSite().first,
          'https://medappnl.atlassian.net');
    });

    test('a task can go back to someday, keeping its project', () async {
      await repo.addTask('Rewrite onboarding',
          date: '2026-07-28', tagId: 'moxify');
      final task = (await repo.watchTasks().first).single;

      await repo.demoteToSomeday(task);

      expect(await repo.watchTasks().first, isEmpty,
          reason: 'it is no longer a thing for a day');
      final parked = (await repo.watchSomeday().first).single;
      expect(parked.title, 'Rewrite onboarding');
      expect(parked.tagId, 'moxify');
    });

    test('deleteTask removes it', () async {
      await repo.addTask('Set out blue can', date: '2026-07-15');
      final task = (await repo.watchTasks().first).single;

      await repo.deleteTask(task);

      expect(await repo.watchTasks().first, isEmpty);
    });
  });

  group('tags', () {
    test('upsertTag creates, then updates in place', () async {
      const tag =
          Tag(id: 'moxify', name: 'Moxify', colorIndex: 1, iconIndex: 0, sortOrder: 0);
      await repo.upsertTag(tag);
      expect((await repo.watchTags().first).single.name, 'Moxify');

      await repo.upsertTag(
        const Tag(
            id: 'moxify',
            name: 'Moxify Pro',
            colorIndex: 4,
            iconIndex: 2,
            sortOrder: 0),
      );

      final tags = await repo.watchTags().first;
      expect(tags, hasLength(1));
      expect(tags.single.name, 'Moxify Pro');
      expect(tags.single.colorIndex, 4);
    });

    test('watchTags emits them in sortOrder', () async {
      await repo.upsertTag(const Tag(
          id: 'c', name: 'Third', colorIndex: 0, iconIndex: 0, sortOrder: 2));
      await repo.upsertTag(const Tag(
          id: 'a', name: 'First', colorIndex: 0, iconIndex: 0, sortOrder: 0));
      await repo.upsertTag(const Tag(
          id: 'b', name: 'Second', colorIndex: 0, iconIndex: 0, sortOrder: 1));

      expect(
        (await repo.watchTags().first).map((t) => t.name).toList(),
        ['First', 'Second', 'Third'],
      );
    });
  });

  group('daily note', () {
    test('saveNote and watchNote roundtrip', () async {
      await repo.saveNote('2026-07-15', 'Release day!!!');
      expect(await repo.watchNote('2026-07-15').first,
          'Release day!!!');
    });

    test('watchNote emits an empty string for a day with no document',
        () async {
      expect(await repo.watchNote('2026-01-01').first, '');
    });

    test('saveNote overwrites the note but keeps the rest of the day document',
        () async {
      // Phase 2 stores the daily question answers alongside the note.
      final day = firestore
          .collection('users')
          .doc('bas')
          .collection('days')
          .doc('2026-07-15');
      await day.set({'questionAnswers': {'travel': 'Bike'}});

      await repo.saveNote('2026-07-15', 'First draft');
      await repo.saveNote('2026-07-15', 'Second draft');

      expect(await repo.watchNote('2026-07-15').first, 'Second draft');
      expect((await day.get()).data()!['questionAnswers'], {'travel': 'Bike'});
    });
  });

  test('data is scoped to its own user', () async {
    await repo.addTask('Private', date: '2026-07-15');
    await repo.saveNote('2026-07-15', 'Mine');

    final other = SeedlingRepo(firestore, 'someone-else');
    expect(await other.watchTasks().first, isEmpty);
    expect(await other.watchNote('2026-07-15').first, '');
  });
}
