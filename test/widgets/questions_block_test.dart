import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/models/daily_question.dart';
import 'package:seedling/widgets/questions_block.dart';

import '../util/golden/golden_utils.dart';

const _travel = DailyQuestion(
  id: 'travel',
  label: 'Work travel',
  emoji: '🚲',
  options: ['Home', 'OV', 'Bike'],
  sortOrder: 0,
);

const _cycled = DailyQuestion(
  id: 'gym',
  label: 'Moved my body',
  options: [],
  sortOrder: 1,
);

Widget _block({
  Map<String, String> answers = const {},
  void Function(DailyQuestion, String?)? onAnswer,
}) =>
    Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: QuestionsBlock(
            questions: const [_travel, _cycled],
            answers: answers,
            onAnswer: onAnswer ?? (_, _) {},
          ),
        ),
      ),
    );

void main() {
  goldenForSizes('daily questions unanswered', 'questions_open',
      [GoldenSize.phone], () => _block());

  goldenForSizes(
    'daily questions half answered',
    'questions_partial',
    [GoldenSize.phone],
    () => _block(answers: const {'travel': 'Bike'}),
  );

  goldenForSizes(
    'daily questions all answered and collapsed',
    'questions_collapsed',
    [GoldenSize.phone],
    () => _block(answers: const {'travel': 'Bike', 'gym': 'yes'}),
  );

  testWidgets('collapses to a summary once everything is answered',
      (tester) async {
    await tester.pumpWidget(
      wrapApp(_block(answers: const {'travel': 'OV', 'gym': 'yes'})),
    );

    // One line, not a heading with a summary under it — it has to fit beside
    // the date.
    expect(find.text('Daily — all answered 2/2'), findsOneWidget);
    expect(find.text('Work travel'), findsNothing);
  });

  testWidgets('stays open while an answer is still missing', (tester) async {
    await tester.pumpWidget(wrapApp(_block(answers: const {'travel': 'OV'})));

    expect(find.textContaining('All answered'), findsNothing);
    expect(find.text('Work travel'), findsOneWidget);
  });

  testWidgets('a collapsed block opens again when tapped', (tester) async {
    await tester.pumpWidget(
      wrapApp(_block(answers: const {'travel': 'OV', 'gym': 'yes'})),
    );

    await tester.tap(find.text('Daily — all answered 2/2'));
    await tester.pumpAndSettle();

    expect(find.text('Work travel'), findsOneWidget);
  });

  testWidgets('picking a chip reports the choice', (tester) async {
    final given = <(String, String?)>[];
    await tester.pumpWidget(
      wrapApp(_block(onAnswer: (q, v) => given.add((q.id, v)))),
    );

    await tester.tap(find.text('Bike'));

    expect(given, [('travel', 'Bike')]);
  });

  testWidgets('tapping the chosen chip again clears it', (tester) async {
    final given = <(String, String?)>[];
    await tester.pumpWidget(wrapApp(_block(
      answers: const {'travel': 'Bike'},
      onAnswer: (q, v) => given.add((q.id, v)),
    )));

    await tester.tap(find.text('Bike'));

    expect(given, [('travel', null)]);
  });

  testWidgets('a plain check ticks on', (tester) async {
    final given = <(String, String?)>[];
    await tester.pumpWidget(
      wrapApp(_block(onAnswer: (q, v) => given.add((q.id, v)))),
    );

    await tester.tap(find.byType(QuestionCheck));

    expect(given, [('gym', 'yes')]);
  });

  testWidgets('a ticked check clears when tapped again', (tester) async {
    final given = <(String, String?)>[];
    await tester.pumpWidget(wrapApp(_block(
      answers: const {'gym': 'yes'},
      onAnswer: (q, v) => given.add((q.id, v)),
    )));

    await tester.tap(find.byType(QuestionCheck));

    expect(given, [('gym', null)]);
  });

  testWidgets('an empty question list renders nothing at all', (tester) async {
    await tester.pumpWidget(wrapApp(Scaffold(
      body: QuestionsBlock(
        questions: const [],
        answers: const {},
        onAnswer: (_, _) {},
      ),
    )));

    expect(find.byType(SizedBox), findsWidgets);
    expect(find.text('Daily'), findsNothing);
  });
}
