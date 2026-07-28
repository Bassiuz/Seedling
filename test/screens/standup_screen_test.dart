import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/logic/standup.dart';
import 'package:seedling/models/tag.dart';
import 'package:seedling/models/task.dart';
import 'package:seedling/screens/standup_screen.dart';

import '../util/golden/golden_utils.dart';

const _today = '2026-07-28';
const _yesterday = '2026-07-27';

const _tags = {
  'moxify':
      Tag(id: 'moxify', name: 'Moxify', colorIndex: 6, iconIndex: 1, sortOrder: 0),
};

Task _task(String title,
        {String date = _today, String? done, String? time, String? tagId}) =>
    Task(
        id: title,
        title: title,
        date: date,
        createdDate: date,
        time: time,
        tagId: tagId,
        completedOnDate: done);

final _fixture = [
  _task('Shipped the promo video',
      date: _yesterday, done: _yesterday, tagId: 'moxify'),
  _task('Fixed the rollover bug', date: _yesterday, done: _yesterday),
  _task('Standup', time: '09:30'),
  _task('Write the release notes', tagId: 'moxify'),
  _task('Book the vet', done: _today),
];

Widget _standup(List<Task> tasks) => StandupView(
      standup: standupFor(tasks, _today),
      tags: _tags,
    );

void main() {
  goldenForSizes(
    'standup: yesterday done, today planned',
    'standup',
    [GoldenSize.phone, GoldenSize.eink],
    () => _standup(_fixture),
  );

  goldenForSizes(
    'standup with nothing to report',
    'standup_empty',
    [GoldenSize.phone],
    () => _standup(const []),
  );

  testWidgets('yesterday and today are kept apart', (tester) async {
    await tester.pumpWidget(wrapApp(_standup(_fixture)));

    expect(find.text('Shipped the promo video'), findsOneWidget);
    expect(find.text('Write the release notes'), findsOneWidget);
    // Yesterday's work is not repeated under today.
    expect(find.text('Fixed the rollover bug'), findsOneWidget);
  });

  testWidgets('nothing on the page can be changed', (tester) async {
    await tester.pumpWidget(wrapApp(_standup(_fixture)));

    // No checkboxes, no menus: it is something to read out.
    expect(find.byType(Checkbox), findsNothing);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('something finished today is struck through, not hidden',
      (tester) async {
    await tester.pumpWidget(wrapApp(_standup(_fixture)));

    final done = tester.widget<Text>(find.text('Book the vet'));
    expect(done.style?.decoration, TextDecoration.lineThrough);
  });
}
