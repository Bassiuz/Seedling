import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/models/tag.dart';
import 'package:seedling/models/task.dart';
import 'package:seedling/widgets/task_tile.dart';

import '../util/golden/golden_utils.dart';

const _today = '2026-07-23';
const _tuesday = '2026-07-21';

const _moxify =
    Tag(id: 'moxify', name: 'Moxify', colorIndex: 6, iconIndex: 1, sortOrder: 0);

Task _task({
  String title = 'Edit the onboarding copy',
  String date = _today,
  String? time,
  String? tagId,
  String? completedOnDate,
}) =>
    Task(
      id: 'x',
      title: title,
      date: date,
      createdDate: date,
      time: time,
      tagId: tagId,
      completedOnDate: completedOnDate,
    );

Widget _tile(
  Task task, {
  String shownDay = _today,
  Tag? tag,
  VoidCallback? onToggle,
  VoidCallback? onMenu,
}) =>
    TaskTile(
      task: task,
      shownDay: shownDay,
      tag: tag,
      onToggle: onToggle ?? () {},
      onMenu: onMenu ?? () {},
    );

/// Every state of the tile in one image, so a visual change is reviewed once.
Widget _gallery() => Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _tile(_task()),
              _tile(_task(title: 'Dentist appointment', time: '09:00')),
              _tile(_task(title: 'Make Shorts clip', tagId: 'moxify'),
                  tag: _moxify),
              _tile(_task(title: 'Afwas doen', date: _tuesday)),
              _tile(_task(
                  title: 'Water the greenhouse', completedOnDate: _today)),
              _tile(_task(
                  title: 'Set out blue can',
                  date: _tuesday,
                  completedOnDate: '2026-07-22')),
            ],
          ),
        ),
      ),
    );

void main() {
  goldenForSizes('task tile states', 'task_tile_states',
      [GoldenSize.phone], _gallery);

  testWidgets('an open task carried from an earlier day says where it is from',
      (tester) async {
    await tester.pumpWidget(
      wrapApp(Scaffold(body: _tile(_task(date: _tuesday)))),
    );

    expect(find.text('from Jul 21'), findsOneWidget);
  });

  testWidgets('a task planned for the day shown carries no origin note',
      (tester) async {
    await tester.pumpWidget(wrapApp(Scaffold(body: _tile(_task()))));

    expect(find.textContaining('from'), findsNothing);
  });

  testWidgets('a task finished on a later day says when it was done',
      (tester) async {
    await tester.pumpWidget(
      wrapApp(Scaffold(
        body: _tile(
          _task(date: _tuesday, completedOnDate: '2026-07-22'),
          shownDay: _tuesday,
        ),
      )),
    );

    expect(find.text('done Wed 22'), findsOneWidget);
  });

  testWidgets('tapping an open task toggles it', (tester) async {
    var toggles = 0;
    await tester.pumpWidget(
      wrapApp(Scaffold(body: _tile(_task(), onToggle: () => toggles++))),
    );

    await tester.tap(find.byType(TaskCheckbox));

    expect(toggles, 1);
  });

  testWidgets('tapping a task finished on a later day does nothing',
      (tester) async {
    var toggles = 0;
    await tester.pumpWidget(
      wrapApp(Scaffold(
        body: _tile(
          _task(date: _tuesday, completedOnDate: '2026-07-22'),
          shownDay: _tuesday,
          onToggle: () => toggles++,
        ),
      )),
    );

    await tester.tap(find.byType(TaskCheckbox));

    expect(toggles, 0);
  });

  testWidgets('long-pressing opens the menu', (tester) async {
    var menus = 0;
    await tester.pumpWidget(
      wrapApp(Scaffold(body: _tile(_task(), onMenu: () => menus++))),
    );

    await tester.longPress(find.text('Edit the onboarding copy'));

    expect(menus, 1);
  });
}
