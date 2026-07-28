import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/data/seedling_repo.dart';
import 'package:seedling/models/review_template.dart';
import 'package:seedling/models/week_review.dart';
import 'package:seedling/screens/week_review_screen.dart';

import '../util/golden/golden_utils.dart';

const _template = ReviewTemplate(
  goalBlocks: [
    GoalBlock(title: 'Quarterly Goals', goals: [
      'Implement a YOLO 26 model and increase Android scanning speed',
      'Bike when dry and not freezing',
    ]),
    GoalBlock(title: 'Yearly Goals', goals: ['100 monthly users for Moxify']),
  ],
  questions: [
    'What did I do since last week review?',
    'What is going to be a lasting memory of this week?',
  ],
  moodEmoji: ['🤔', '😄', '😢', '💻'],
);

final _review = WeekReview(
  weekKey: '2026-W31',
  goals: _template.goalBlocks,
  answers: const {
    'What is going to be a lasting memory of this week?':
        'Me getting back on track! #laserfocus',
  },
  moodLines: const [
    MoodLine(emoji: '😄', text: 'Work is getting a bit better now.'),
    MoodLine(emoji: '🦴', text: 'My collarbone is getting a lot better.'),
  ],
);

Widget _view({
  WeekReview? review,
  List<String> recentEmoji = const [],
  void Function(String, String)? onAnswer,
  void Function(String, String)? onAddMood,
  void Function(int)? onRemoveMood,
}) =>
    WeekReviewView(
      review: review ?? _review,
      template: _template,
      recentEmoji: recentEmoji,
      onAnswer: onAnswer ?? (_, _) {},
      onAddMood: onAddMood ?? (_, _) {},
      onRemoveMood: onRemoveMood ?? (_) {},
    );

void main() {
  goldenForSizes('week review', 'week_review',
      [GoldenSize.phone, GoldenSize.mac], () => _view());

  goldenForSizes(
    'week review not yet written',
    'week_review_blank',
    [GoldenSize.phone],
    () => _view(review: WeekReview.from('2026-W32', _template)),
  );

  test('a new review freezes the goals as they are now', () {
    final review = WeekReview.from('2026-W31', _template);

    expect(review.goals.first.title, 'Quarterly Goals');
    expect(review.goals.first.goals, hasLength(2));

    // Changing the template afterwards must not rewrite history.
    const later = ReviewTemplate(
      goalBlocks: [GoalBlock(title: 'Quarterly Goals', goals: ['Something new'])],
    );
    expect(WeekReview.from('2026-W32', later).goals.first.goals,
        ['Something new']);
    expect(review.goals.first.goals.first,
        startsWith('Implement a YOLO 26 model'));
  });

  test('a review with nothing written in it counts as empty', () {
    expect(WeekReview.from('2026-W31', _template).isEmpty, isTrue);
    expect(_review.isEmpty, isFalse);
  });

  testWidgets('the frozen goals are shown, not edited here', (tester) async {
    configureSize(tester, GoldenSize.mac);
    await tester.pumpWidget(wrapApp(_view()));

    expect(find.textContaining('YOLO 26'), findsOneWidget);
    expect(find.text('Quarterly Goals'), findsOneWidget);
  });

  testWidgets('writing an answer reports it against its question',
      (tester) async {
    configureSize(tester, GoldenSize.mac);
    final answers = <String, String>{};
    await tester.pumpWidget(
      wrapApp(_view(onAnswer: (q, a) => answers[q] = a)),
    );

    await tester.enterText(
        find.byType(TextField).first, 'Got back into my routines');

    expect(answers['What did I do since last week review?'],
        'Got back into my routines');
  });

  testWidgets('an observation is added under the chosen emoji', (tester) async {
    configureSize(tester, GoldenSize.mac);
    final added = <(String, String)>[];
    await tester.pumpWidget(wrapApp(_view(onAddMood: (e, t) => added.add((e, t)))));

    await tester.tap(find.text('😢').last);
    await tester.pump();
    await tester.enterText(find.byType(TextField).last, 'Worried about Rik');
    await tester.testTextInput.receiveAction(TextInputAction.done);

    expect(added, [('😢', 'Worried about Rik')]);
  });

  testWidgets('an observation can be taken back out', (tester) async {
    configureSize(tester, GoldenSize.mac);
    final removed = <int>[];
    await tester.pumpWidget(wrapApp(_view(onRemoveMood: removed.add)));

    await tester.tap(find.byTooltip('Remove').last);

    expect(removed, [1]);
  });

  testWidgets('the strip shows what was used lately, newest first',
      (tester) async {
    configureSize(tester, GoldenSize.mac);
    await tester.pumpWidget(
      wrapApp(_view(recentEmoji: const ['🎯', '🚲', '📚'])),
    );

    // The first of the strip is also echoed next to the input as the current
    // choice, so compare two that appear only in the strip itself.
    final bike = tester.getTopLeft(find.text('🚲')).dx;
    final books = tester.getTopLeft(find.text('📚')).dx;
    expect(bike, lessThan(books), reason: 'the strip keeps recency order');
    expect(find.text('🎯'), findsWidgets, reason: 'newest is offered');

    // The template's own starters give way to what you actually use.
    expect(find.text('💻'), findsNothing);
  });

  testWidgets('before anything is used the template starters are offered',
      (tester) async {
    configureSize(tester, GoldenSize.mac);
    await tester.pumpWidget(wrapApp(_view()));

    expect(find.text('💻'), findsOneWidget);
  });

  testWidgets('an emoji that is not on the strip can just be typed',
      (tester) async {
    configureSize(tester, GoldenSize.mac);
    final added = <(String, String)>[];
    await tester.pumpWidget(wrapApp(_view(
      recentEmoji: const ['🎯'],
      onAddMood: (e, t) => added.add((e, t)),
    )));

    // The narrow box beside the strip takes any emoji.
    await tester.enterText(find.widgetWithText(TextField, '+'), '🎉');
    await tester.pump();
    await tester.enterText(
        find.widgetWithText(TextField, 'Add an observation…'), 'Shipped it');
    await tester.testTextInput.receiveAction(TextInputAction.done);

    expect(added, [('🎉', 'Shipped it')]);
  });

  testWidgets('typing several emoji keeps only the first', (tester) async {
    configureSize(tester, GoldenSize.mac);
    final added = <(String, String)>[];
    await tester.pumpWidget(wrapApp(_view(
      recentEmoji: const ['🎯'],
      onAddMood: (e, t) => added.add((e, t)),
    )));

    await tester.enterText(find.widgetWithText(TextField, '+'), '🎉🚀');
    await tester.pump();
    await tester.enterText(
        find.widgetWithText(TextField, 'Add an observation…'), 'One mark');
    await tester.testTextInput.receiveAction(TextInputAction.done);

    expect(added.single.$1, '🎉');
  });

  testWidgets('a first visit falls back to the starter template',
      (tester) async {
    configureSize(tester, GoldenSize.mac);
    final repo = SeedlingRepo(FakeFirebaseFirestore(), 'bas');

    await tester.pumpWidget(
      wrapApp(WeekReviewScreen(repo: repo, weekKey: '2026-W31')),
    );
    await tester.pumpAndSettle();

    expect(find.text('What is going to be a lasting memory of this week?'),
        findsOneWidget);
    expect(find.text('2026-W31'), findsOneWidget);
    expect(find.textContaining('since last week review'), findsNothing,
        reason: 'that prompt was dropped from the starter template');
  });

  testWidgets('an emoji on the clipboard can be pasted in', (tester) async {
    // Raycast and friends copy the emoji as well as pasting it; this is the
    // route that does not depend on the paste reaching the field.
    final added = <(String, String)>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => call.method == 'Clipboard.getData'
          ? <String, dynamic>{'text': '🪴 potted'}
          : null,
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    configureSize(tester, GoldenSize.mac);
    await tester
        .pumpWidget(wrapApp(_view(onAddMood: (e, t) => added.add((e, t)))));
    await tester.ensureVisible(find.byTooltip('Paste an emoji'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Paste an emoji'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextField, 'Add an observation…'), 'Repotted');
    await tester.testTextInput.receiveAction(TextInputAction.done);

    expect(added, [('🪴', 'Repotted')]);
  });
}
