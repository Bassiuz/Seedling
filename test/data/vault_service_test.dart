import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/data/seedling_repo.dart';
import 'package:seedling/data/vault_exporter.dart';
import 'package:seedling/data/vault_service.dart';
import 'package:seedling/models/week_review.dart';

const _day = '2026-07-27';

void main() {
  late Directory root;
  late SeedlingRepo repo;
  late VaultService service;

  setUp(() {
    root = Directory.systemTemp.createTempSync('seedling_vault_test');
    repo = SeedlingRepo(FakeFirebaseFirestore(), 'bas');
    service = VaultService(repo, VaultExporter(root));
  });

  tearDown(() => root.deleteSync(recursive: true));

  bool exists(String path) => File('${root.path}/$path').existsSync();
  String read(String path) => File('${root.path}/$path').readAsStringSync();

  test('every written review gets a file', () async {
    await repo.saveReview(const WeekReview(
      weekKey: '2026-W30',
      goals: [],
      answers: {'What went well?': 'Shipped it.'},
      moodLines: [],
    ));

    await service.exportAll();

    expect(read('reviews/2026-W30.md'), contains('Shipped it.'));
  });

  test('a day with only a note is exported too', () async {
    // It used to take a task on the day for the day to exist at all.
    await repo.saveNote(_day, 'Quiet one.');

    await service.exportAll();

    expect(read('days/2026/2026-07-27.md'), contains('Quiet one.'));
  });

  test('a day with nothing on it gets no file', () async {
    await service.exportAll();

    expect(exists('days/2026/2026-07-27.md'), isFalse);
  });
}
