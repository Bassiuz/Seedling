import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/models/review_template.dart';
import 'package:seedling/screens/goals_screen.dart';

import '../util/golden/golden_utils.dart';

const _template = ReviewTemplate(
  goalBlocks: [
    GoalBlock(title: 'Quarterly Goals', goals: ['Bike when dry']),
    GoalBlock(title: 'Yearly Goals', goals: ['100 monthly users for Moxify']),
  ],
);

void main() {
  goldenForSizes(
    'goals',
    'goals',
    [GoldenSize.phone],
    () => GoalsView(
      template: _template,
      onAddGoal: (_, _) {},
      onRemoveGoal: (_, _) {},
      onRemoveBlock: (_) {},
    ),
  );

  group('editing lists', () {
    test('a goal joins the list it belongs to and no other', () {
      final after = _template.withGoalAdded('Quarterly Goals', 'Ship Seedling');

      expect(after.goalBlocks.first.goals, ['Bike when dry', 'Ship Seedling']);
      expect(after.goalBlocks.last.goals, ['100 monthly users for Moxify']);
    });

    test('a goal can be taken off again', () {
      expect(
        _template.withGoalRemoved('Quarterly Goals', 0).goalBlocks.first.goals,
        isEmpty,
      );
    });

    test('removing an index that is not there changes nothing', () {
      expect(
        _template.withGoalRemoved('Quarterly Goals', 9).goalBlocks.first.goals,
        ['Bike when dry'],
      );
    });

    test('a list added by accident can be dropped', () {
      const withStray = ReviewTemplate(goalBlocks: [
        GoalBlock(title: 'Quarterly Goals', goals: ['Bike when dry']),
        GoalBlock(title: 'test list', goals: []),
      ]);

      final after = withStray.withBlockRemoved('test list');

      expect(after.goalBlocks.map((b) => b.title).toList(),
          ['Quarterly Goals']);
    });

    test('removing a list that is not there changes nothing', () {
      expect(_template.withBlockRemoved('nope').goalBlocks, hasLength(2));
    });

    test('editing never touches the questions or the emoji palette', () {
      const full = ReviewTemplate(
        goalBlocks: [GoalBlock(title: 'Q', goals: [])],
        questions: ['Anything?'],
        moodEmoji: ['ok'],
      );

      final after = full.withGoalAdded('Q', 'something');

      expect(after.questions, ['Anything?']);
      expect(after.moodEmoji, ['ok']);
    });

    test('editing the template leaves an existing snapshot alone', () {
      // A week review holds its own copy; this is what keeps history honest.
      final frozen = _template.goalBlocks;

      _template.withGoalAdded('Quarterly Goals', 'Something new');

      expect(frozen.first.goals, ['Bike when dry']);
    });
  });

  testWidgets('the view reports which list a goal was typed into',
      (tester) async {
    configureSize(tester, GoldenSize.mac);
    final added = <(String, String)>[];
    await tester.pumpWidget(wrapApp(GoalsView(
      template: _template,
      onAddGoal: (block, goal) => added.add((block, goal)),
      onRemoveGoal: (_, _) {},
      onRemoveBlock: (_) {},
    )));

    await tester.enterText(
        find.widgetWithText(TextField, 'Add a goal…').last, 'Retirement plan');
    await tester.testTextInput.receiveAction(TextInputAction.done);

    expect(added, [('Yearly Goals', 'Retirement plan')]);
  });
}
