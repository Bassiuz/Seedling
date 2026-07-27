import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/models/tag.dart';
import 'package:seedling/models/task.dart';
import 'package:seedling/widgets/add_task_field.dart';
import 'package:seedling/widgets/note_block.dart';
import 'package:seedling/widgets/tasks_block.dart';
import 'package:seedling/widgets/timed_block.dart';

import '../util/golden/golden_utils.dart';

const _today = '2026-07-15';

const _tags = {
  'riley': Tag(
      id: 'riley', name: 'Riley', colorIndex: 9, iconIndex: 10, sortOrder: 0),
  'moxify': Tag(
      id: 'moxify', name: 'Moxify', colorIndex: 6, iconIndex: 1, sortOrder: 1),
};

Task _task(String id, String title,
        {String? time, String? tagId, String date = _today}) =>
    Task(
      id: id,
      title: title,
      date: date,
      createdDate: date,
      time: time,
      tagId: tagId,
    );

final _timed = [
  _task('1', 'Vet appointment', time: '09:00'),
  _task('2', 'Fix Shipaton promo video', time: '17:00', tagId: 'moxify'),
  _task('3', 'Give Riley bath', time: '18:00', tagId: 'riley'),
];

final _untimed = [
  _task('4', 'Edit Cozy Zone', date: '2026-07-13'),
  _task('5', 'Make Shorts clip for CF and CZ', tagId: 'moxify'),
];

Widget _blocks({required bool filled}) => Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TimedBlock(
                tasks: filled ? _timed : const [],
                tags: _tags,
                shownDay: _today,
                onToggle: (_) {},
                onMenu: (_) {},
              ),
              const SizedBox(height: 28),
              TasksBlock(
                tasks: filled ? _untimed : const [],
                tags: _tags,
                shownDay: _today,
                onToggle: (_) {},
                onMenu: (_) {},
                onAdd: (_, {tagId, time}) {},
              ),
              const SizedBox(height: 28),
              NoteBlock(
                text: filled
                    ? 'Parchment release day!!!\n\nIt has been great. Got some '
                        'really nice messages from people saying this is what '
                        'they had been looking for.'
                    : '',
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      ),
    );

void main() {
  goldenForSizes(
    'day blocks with content',
    'blocks_filled',
    [GoldenSize.phone, GoldenSize.eink],
    () => _blocks(filled: true),
  );

  goldenForSizes(
    'day blocks on an empty day',
    'blocks_empty',
    [GoldenSize.phone],
    () => _blocks(filled: false),
  );

  testWidgets('an empty timed block says so', (tester) async {
    await tester.pumpWidget(wrapApp(_blocks(filled: false)));

    expect(find.text('Nothing timed'), findsOneWidget);
  });

  testWidgets('a filled timed block lists its tasks in order', (tester) async {
    await tester.pumpWidget(wrapApp(_blocks(filled: true)));

    expect(find.text('Vet appointment'), findsOneWidget);
    expect(find.text('Nothing timed'), findsNothing);
  });

  testWidgets('the add field reports a typed task and then clears',
      (tester) async {
    final added = <String>[];
    await tester.pumpWidget(
      wrapApp(Scaffold(
          body: AddTaskField(onAdd: (t, {tagId, time}) => added.add(t)))),
    );

    await tester.enterText(find.byType(TextField), 'Water the plants');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(added, ['Water the plants']);
    expect(find.text('Water the plants'), findsNothing);
  });

  testWidgets('the add field ignores blank input', (tester) async {
    final added = <String>[];
    await tester.pumpWidget(
      wrapApp(Scaffold(
          body: AddTaskField(onAdd: (t, {tagId, time}) => added.add(t)))),
    );

    await tester.enterText(find.byType(TextField), '   ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(added, isEmpty);
  });

  testWidgets('a picked tag rides along with the new task and then resets',
      (tester) async {
    final adds = <(String, String?)>[];
    await tester.pumpWidget(wrapApp(Scaffold(
      body: AddTaskField(
        tags: _tags.values.toList(),
        onAdd: (title, {tagId, time}) => adds.add((title, tagId)),
      ),
    )));

    await tester.tap(find.byTooltip('Pick a tag'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Moxify'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Record voiceover');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(adds, [('Record voiceover', 'moxify')]);
    // The chip is gone again, so the next task does not silently inherit it.
    expect(find.byTooltip('Pick a tag'), findsOneWidget);
  });

  testWidgets('the tag button does nothing when there are no tags yet',
      (tester) async {
    await tester.pumpWidget(wrapApp(
      Scaffold(body: AddTaskField(onAdd: (_, {tagId, time}) {})),
    ));

    await tester.tap(find.byTooltip('Pick a tag'));
    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('the note reports every keystroke', (tester) async {
    final edits = <String>[];
    await tester.pumpWidget(
      wrapApp(Scaffold(body: NoteBlock(text: '', onChanged: edits.add))),
    );

    await tester.enterText(find.byType(TextField), 'Took Riley to the vet');

    expect(edits.last, 'Took Riley to the vet');
  });

  testWidgets('the note does not fight the cursor when a sync arrives',
      (tester) async {
    Widget note(String text) =>
        wrapApp(Scaffold(body: NoteBlock(text: text, onChanged: (_) {})));

    await tester.pumpWidget(note(''));
    await tester.enterText(find.byType(TextField), 'Half a sentence');

    // Same text arriving from the stream must not reset the field.
    await tester.pumpWidget(note('Half a sentence'));

    expect(find.text('Half a sentence'), findsOneWidget);
  });

  testWidgets('the note adopts text for a different day', (tester) async {
    Widget note(String text) =>
        wrapApp(Scaffold(body: NoteBlock(text: text, onChanged: (_) {})));

    await tester.pumpWidget(note('Yesterday'));
    await tester.pumpWidget(note('Today'));

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsNothing);
  });
}
