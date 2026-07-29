import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/data/seedling_repo.dart';
import 'package:seedling/models/someday_item.dart';
import 'package:seedling/models/tag.dart';
import 'package:seedling/screens/someday_screen.dart';

import '../util/golden/golden_utils.dart';

const _tags = {
  'moxify':
      Tag(id: 'moxify', name: 'Moxify', colorIndex: 6, iconIndex: 1, sortOrder: 0),
  'home':
      Tag(id: 'home', name: 'Home', colorIndex: 3, iconIndex: 4, sortOrder: 1),
};

const _items = [
  SomedayItem(id: '1', title: 'YOLO 26 scanning speed', tagId: 'moxify', priority: 0),
  SomedayItem(id: '2', title: 'Rewrite the onboarding', tagId: 'moxify', priority: 1),
  SomedayItem(id: '3', title: 'Fix the shed door', tagId: 'home', priority: 2),
  SomedayItem(id: '4', title: 'Read that retirement book', priority: 3),
];

Widget _someday({
  List<SomedayItem> items = _items,
  void Function(SomedayItem)? onPromote,
  void Function(SomedayItem)? onDelete,
  void Function(SomedayItem, String?)? onMove,
}) =>
    SomedayView(
      items: items,
      tags: _tags,
      onAdd: (_, _) {},
      onPromote: onPromote ?? (_) {},
      onDelete: onDelete ?? (_) {},
      onMove: onMove,
    );

/// Picks an idea up and drops it on a heading. Long-press, because a plain
/// drag would fight the list's own scrolling on a phone.
Future<void> dragOnto(
    WidgetTester tester, String title, String project) async {
  final drag = await tester.startGesture(tester.getCenter(find.text(title)));
  await tester.pump(kLongPressTimeout + const Duration(milliseconds: 20));
  await drag.moveTo(tester.getCenter(find.text(project)));
  await tester.pump();
  await drag.up();
  await tester.pumpAndSettle();
}

void main() {
  goldenForSizes('someday', 'someday', [GoldenSize.phone, GoldenSize.mac],
      () => _someday());

  goldenForSizes('someday when empty', 'someday_empty', [GoldenSize.phone],
      () => _someday(items: const []));

  test('groups by project and keeps priority order inside each', () {
    final grouped = SomedayView.group(_items);

    expect(grouped.keys.toSet(), {'moxify', 'home', null});
    expect(grouped['moxify']!.map((i) => i.title).toList(),
        ['YOLO 26 scanning speed', 'Rewrite the onboarding']);
    expect(grouped[null]!.single.title, 'Read that retirement book');
  });

  testWidgets('the untagged group is shown last', (tester) async {
    configureSize(tester, GoldenSize.mac);
    await tester.pumpWidget(wrapApp(_someday()));

    final moxify = tester.getTopLeft(find.text('Moxify')).dy;
    final none = tester.getTopLeft(find.text('No project')).dy;

    expect(none, greaterThan(moxify));
  });

  testWidgets('doing one today reports it', (tester) async {
    final promoted = <String>[];
    await tester.pumpWidget(
      wrapApp(_someday(onPromote: (i) => promoted.add(i.title))),
    );

    await tester.tap(find.byTooltip('Do it today').first);

    expect(promoted, ['YOLO 26 scanning speed']);
  });

  group('wired to Firestore', () {
    testWidgets('promoting adds a task for the day and clears the item',
        (tester) async {
      final repo = SeedlingRepo(FakeFirebaseFirestore(), 'bas');
      await repo.addSomeday('Fix the shed door', tagId: 'home', priority: 0);

      await tester.pumpWidget(
        wrapApp(SomedayScreen(repo: repo, today: '2026-07-27')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Do it today'));
      await tester.pumpAndSettle();

      final task = (await repo.watchTasks().first).single;
      expect(task.title, 'Fix the shed door');
      expect(task.date, '2026-07-27');
      expect(task.tagId, 'home');
      expect(await repo.watchSomeday().first, isEmpty);
    });

    testWidgets('parking an idea stores it', (tester) async {
      final repo = SeedlingRepo(FakeFirebaseFirestore(), 'bas');
      await tester.pumpWidget(
        wrapApp(SomedayScreen(repo: repo, today: '2026-07-27')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextField, 'Park an idea…'), 'Buy a new saddle');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect((await repo.watchSomeday().first).single.title,
          'Buy a new saddle');
    });
  });

  group('refiling by dragging', () {
    testWidgets('an idea can be dropped onto another project', (tester) async {
      configureSize(tester, GoldenSize.mac);
      final moved = <(String, String?)>[];
      await tester.pumpWidget(wrapApp(
        _someday(onMove: (item, tagId) => moved.add((item.id, tagId))),
      ));

      await dragOnto(tester, 'Fix the shed door', 'Moxify');

      expect(moved, [('3', 'moxify')]);
    });

    testWidgets('and out of a project entirely', (tester) async {
      configureSize(tester, GoldenSize.mac);
      final moved = <(String, String?)>[];
      await tester.pumpWidget(wrapApp(
        _someday(onMove: (item, tagId) => moved.add((item.id, tagId))),
      ));

      await dragOnto(tester, 'Fix the shed door', 'No project');

      expect(moved, [('3', null)]);
    });

    testWidgets('dropping it back where it was changes nothing',
        (tester) async {
      configureSize(tester, GoldenSize.mac);
      final moved = <(String, String?)>[];
      await tester.pumpWidget(wrapApp(
        _someday(onMove: (item, tagId) => moved.add((item.id, tagId))),
      ));

      await dragOnto(tester, 'Fix the shed door', 'Home');

      expect(moved, isEmpty);
    });

    testWidgets('an empty project is still somewhere to drop', (tester) async {
      configureSize(tester, GoldenSize.mac);
      final moved = <(String, String?)>[];
      await tester.pumpWidget(wrapApp(_someday(
        items: const [
          SomedayItem(id: '1', title: 'Only idea', tagId: 'moxify',
              priority: 0),
        ],
        onMove: (item, tagId) => moved.add((item.id, tagId)),
      )));

      expect(find.text('Home'), findsOneWidget,
          reason: 'you cannot drop onto a heading that is not drawn');
      await dragOnto(tester, 'Only idea', 'Home');

      expect(moved, [('1', 'home')]);
    });

    testWidgets('without a handler nothing is draggable', (tester) async {
      await tester.pumpWidget(wrapApp(_someday()));

      expect(find.byType(LongPressDraggable<SomedayItem>), findsNothing);
      expect(find.byType(DragTarget<SomedayItem>), findsNothing);
    });
  });
}
