import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/data/seedling_repo.dart';
import 'package:seedling/models/tag.dart';
import 'package:seedling/screens/tags_screen.dart';

import '../util/golden/golden_utils.dart';

const _tags = [
  Tag(id: 'moxify', name: 'Moxify', colorIndex: 6, iconIndex: 1, sortOrder: 0),
  Tag(id: 'riley', name: 'Riley', colorIndex: 9, iconIndex: 10, sortOrder: 1),
  Tag(id: 'health', name: 'Health', colorIndex: 1, iconIndex: 3, sortOrder: 2),
];

void main() {
  goldenForSizes(
    'tags screen',
    'tags_screen',
    [GoldenSize.phone, GoldenSize.eink],
    () => TagsView(tags: _tags, onEdit: (_) {}, onAdd: () {}),
  );

  goldenForSizes(
    'tags screen with no tags',
    'tags_screen_empty',
    [GoldenSize.phone],
    () => TagsView(tags: const [], onEdit: (_) {}, onAdd: () {}),
  );

  goldenForSizes(
    'tag editor',
    'tag_editor',
    [GoldenSize.phone],
    () => Scaffold(
      body: SafeArea(
        child: TagEditor(initial: _tags.first, onSave: (_, _, _) {}),
      ),
    ),
  );

  testWidgets('tapping a tag offers it for editing', (tester) async {
    final edited = <String>[];
    await tester.pumpWidget(wrapApp(
      TagsView(tags: _tags, onEdit: (t) => edited.add(t.name), onAdd: () {}),
    ));

    await tester.tap(find.text('Riley'));

    expect(edited, ['Riley']);
  });

  testWidgets('the editor hands back the name, colour and icon',
      (tester) async {
    (String, int, int)? saved;
    await tester.pumpWidget(wrapApp(Scaffold(
      body: SingleChildScrollView(
        child: TagEditor(
          onSave: (name, color, icon) => saved = (name, color, icon),
        ),
      ),
    )));

    await tester.enterText(find.byType(TextField), '  Fantasy Draft  ');
    await tester.tap(find.text('Save'));

    expect(saved, ('Fantasy Draft', 0, 0));
  });

  testWidgets('the editor refuses to save a nameless tag', (tester) async {
    var saves = 0;
    await tester.pumpWidget(wrapApp(Scaffold(
      body: SingleChildScrollView(
        child: TagEditor(onSave: (_, _, _) => saves++),
      ),
    )));

    await tester.tap(find.text('Save'));

    expect(saves, 0);
  });

  testWidgets('a task can be put on today straight from a project',
      (tester) async {
    configureSize(tester, GoldenSize.mac);
    final added = <(String, String)>[];
    await tester.pumpWidget(wrapApp(TagsView(
      tags: _tags,
      onEdit: (_) {},
      onAdd: () {},
      onAddTask: (tag, title) => added.add((tag.id, title)),
    )));

    await tester.enterText(
        find.widgetWithText(TextField, 'Add to Moxify…'), 'Record voiceover');
    await tester.testTextInput.receiveAction(TextInputAction.done);

    expect(added, [('moxify', 'Record voiceover')]);
  });

  testWidgets('the same line can park it on someday instead', (tester) async {
    configureSize(tester, GoldenSize.mac);
    final parked = <(String, String)>[];
    await tester.pumpWidget(wrapApp(TagsView(
      tags: _tags,
      onEdit: (_) {},
      onAdd: () {},
      onAddTask: (_, _) {},
      onParkIdea: (tag, title) => parked.add((tag.id, title)),
    )));

    await tester.enterText(
        find.widgetWithText(TextField, 'Add to Riley…'), 'New collar');
    await tester.tap(find.byTooltip('Park it on someday').at(1));

    expect(parked, [('riley', 'New collar')]);
  });

  testWidgets('the add lines are hidden when there is nowhere to add to',
      (tester) async {
    configureSize(tester, GoldenSize.mac);
    await tester.pumpWidget(
      wrapApp(TagsView(tags: _tags, onEdit: (_) {}, onAdd: () {})),
    );

    expect(find.textContaining('Add to '), findsNothing);
  });

  test('a new tag gets a readable id from its name', () {
    expect(TagsScreen.idFor('Fantasy Draft'), 'fantasy-draft');
    expect(TagsScreen.idFor('Moxify!!'), 'moxify-');
  });

  testWidgets('saving a new tag stores it', (tester) async {
    final repo = SeedlingRepo(FakeFirebaseFirestore(), 'bas');
    await tester.pumpWidget(wrapApp(TagsScreen(repo: repo, today: '2026-07-28')));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('New tag'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Fantasy Draft');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final stored = (await repo.watchTags().first).single;
    expect(stored.id, 'fantasy-draft');
    expect(stored.name, 'Fantasy Draft');
  });

  testWidgets('renaming keeps the original id so tasks stay attached',
      (tester) async {
    final repo = SeedlingRepo(FakeFirebaseFirestore(), 'bas');
    await repo.upsertTag(_tags.first);

    await tester.pumpWidget(wrapApp(TagsScreen(repo: repo, today: '2026-07-28')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Moxify'));
    await tester.pumpAndSettle();
    // The sheet's own field, not the add-to-project lines behind it.
    await tester.enterText(
        find.widgetWithText(TextField, 'Name').hitTestable(), 'Moxify Pro');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final tags = await repo.watchTags().first;
    expect(tags, hasLength(1));
    expect(tags.single.id, 'moxify');
    expect(tags.single.name, 'Moxify Pro');
  });
}
