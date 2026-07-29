import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/data/seedling_repo.dart';
import 'package:seedling/models/task.dart';
import 'package:seedling/widgets/task_tile.dart';

import '../util/golden/golden_utils.dart';

const _day = '2026-07-28';

Task _task({String title = 'Fix the shed door'}) => Task(
      id: 't',
      title: title,
      date: _day,
      createdDate: _day,
      timeEntries: const {_day: 30},
      completedOnDate: _day,
    );

Widget _tile({VoidCallback? onRename, VoidCallback? onToggle}) => Scaffold(
      body: TaskTile(
        task: _task(),
        shownDay: _day,
        onToggle: onToggle ?? () {},
        onMenu: () {},
        onRename: onRename,
      ),
    );

void main() {
  testWidgets('tapping the title asks to rename it', (tester) async {
    var renames = 0;
    await tester.pumpWidget(wrapApp(_tile(onRename: () => renames++)));

    await tester.tap(find.text('Fix the shed door'));

    expect(renames, 1);
  });

  testWidgets('the checkbox still checks rather than renaming', (tester) async {
    var renames = 0, toggles = 0;
    await tester.pumpWidget(wrapApp(
      _tile(onRename: () => renames++, onToggle: () => toggles++),
    ));

    await tester.tap(find.byType(TaskCheckbox));

    expect(toggles, 1);
    expect(renames, 0);
  });

  testWidgets('without a handler the title is not tappable', (tester) async {
    await tester.pumpWidget(wrapApp(_tile()));

    // Nothing to assert but that it does not throw; the golden views pass no
    // handler and must stay inert.
    await tester.tap(find.text('Fix the shed door'));
  });

  group('the repo', () {
    late SeedlingRepo repo;
    setUp(() => repo = SeedlingRepo(FakeFirebaseFirestore(), 'bas'));

    test('renaming keeps the time logged and the completion', () async {
      await repo.addTask('Fix the shed door', date: _day);
      var stored = (await repo.watchTasks().first).single;
      await repo.logTime(stored, _day, 30);
      await repo.setCompleted(stored, _day);
      stored = (await repo.watchTasks().first).single;

      await repo.renameTask(stored, 'Fix the shed door properly');

      final after = (await repo.watchTasks().first).single;
      expect(after.title, 'Fix the shed door properly');
      expect(after.minutesOn(_day), 30, reason: 'a rename is not a reset');
      expect(after.completedOnDate, _day);
      expect(after.id, stored.id, reason: 'so history stays attached');
    });
  });
}
