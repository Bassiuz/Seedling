import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/data/seedling_repo.dart';
import 'package:seedling/data/vault_exporter.dart';
import 'package:seedling/data/vault_mirror.dart';
import 'package:seedling/logic/rollover.dart';

/// Drives the mirror from live repo data, the way the day page does, and checks
/// a real file lands on disk with the right content.
void main() {
  test('a day edited through the repo ends up in the vault', () async {
    final root = Directory.systemTemp.createTempSync('seedling_live');
    addTearDown(() => root.deleteSync(recursive: true));

    final repo = SeedlingRepo(FakeFirebaseFirestore(), 'bas');
    final mirror = VaultMirror(VaultExporter(root), debounce: Duration.zero);
    addTearDown(mirror.dispose);

    const today = '2026-07-28';
    await repo.addTask('Afwas doen', date: today);
    await repo.saveNote(today, 'Parchment release day!!!');
    await repo.setAnswer(today, 'travel', 'Bike');

    final tasks = await repo.watchTasks().first;

    mirror.day(
      dayKey: today,
      tasks: tasksForDay(tasks, today, today),
      tags: const {},
      note: await repo.watchNote(today).first,
      answers: await repo.watchAnswers(today).first,
    );
    await mirror.flush();

    final file = File('${root.path}/${dayPathFor(today)}');
    expect(file.existsSync(), isTrue, reason: 'the day file was written');

    final contents = file.readAsStringSync();
    expect(contents, contains('- [ ] Afwas doen'));
    expect(contents, contains('Parchment release day!!!'));
    expect(contents, startsWith('---\ndate: 2026-07-28'));
  });
}

String dayPathFor(String dayKey) => 'days/${dayKey.substring(0, 4)}/$dayKey.md';
