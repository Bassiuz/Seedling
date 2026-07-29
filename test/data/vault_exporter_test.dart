import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/data/vault_exporter.dart';
import 'package:seedling/models/someday_item.dart';
import 'package:seedling/models/tag.dart';
import 'package:seedling/models/task.dart';
import 'package:seedling/models/week_review.dart';

void main() {
  late Directory root;
  late VaultExporter exporter;

  setUp(() {
    root = Directory.systemTemp.createTempSync('seedling_vault_test');
    exporter = VaultExporter(root);
  });

  tearDown(() => root.deleteSync(recursive: true));

  String read(String path) => File('${root.path}/$path').readAsStringSync();

  test('a day lands under its year and holds its tasks', () async {
    await exporter.writeDay(
      dayKey: '2026-07-27',
      tasks: [
        Task(
            id: '1',
            title: 'Afwas doen',
            date: '2026-07-27',
            createdDate: '2026-07-27'),
      ],
      tags: const {},
      note: 'Long day.',
    );

    final contents = read('days/2026/2026-07-27.md');
    expect(contents, contains('- [ ] Afwas doen'));
    expect(contents, contains('Long day.'));
  });

  test('writing the same day twice replaces rather than appends', () async {
    Future<void> write(String note) => exporter.writeDay(
        dayKey: '2026-07-27', tasks: const [], tags: const {}, note: note);

    await write('First');
    await write('Second');

    final contents = read('days/2026/2026-07-27.md');
    expect(contents, contains('Second'));
    expect(contents, isNot(contains('First')));
  });

  test('a review lands under its week key', () async {
    await exporter.writeReview(const WeekReview(
      weekKey: '2026-W31',
      answers: {'What did I do?': 'Plenty'},
    ));

    expect(read('reviews/2026-W31.md'), contains('Plenty'));
  });

  test('someday gets one file per project, untagged included', () async {
    const tags = {
      'moxify': Tag(
          id: 'moxify',
          name: 'Moxify',
          colorIndex: 0,
          iconIndex: 0,
          sortOrder: 0),
    };

    await exporter.writeSomeday(const [
      SomedayItem(id: '1', title: 'Importer rewrite', tagId: 'moxify', priority: 0),
      SomedayItem(id: '2', title: 'Read that book', priority: 1),
    ], tags);

    expect(read('someday/moxify.md'), contains('Importer rewrite'));
    expect(read('someday/no-project.md'), contains('Read that book'));
  });

  test('the tag list is written for an agent to read', () async {
    await exporter.writeTags(const [
      Tag(id: 'moxify', name: 'Moxify', colorIndex: 0, iconIndex: 0, sortOrder: 0),
    ]);

    expect(read('tags.md'), contains('- Moxify'));
  });

  test('missing folders are created on the way', () async {
    expect(Directory('${root.path}/days').existsSync(), isFalse);

    await exporter.writeDay(
        dayKey: '2030-01-01', tasks: const [], tags: const {}, note: 'x');

    expect(File('${root.path}/days/2030/2030-01-01.md').existsSync(), isTrue);
  });
}
