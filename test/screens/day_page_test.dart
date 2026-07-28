import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/data/seedling_repo.dart';
import 'package:seedling/logic/day_key.dart';
import 'package:seedling/logic/rollover.dart';
import 'package:seedling/models/tag.dart';
import 'package:seedling/models/daily_question.dart';
import 'package:seedling/models/task.dart';
import 'package:seedling/screens/day_page.dart';
import 'package:seedling/theme/seedling_theme.dart';
import 'package:seedling/widgets/day_header.dart';
import 'package:seedling/widgets/task_tile.dart';

import '../util/golden/golden_utils.dart';
import '../util/shortcut_finder.dart';

const _today = '2026-07-15';

const _tags = {
  'riley': Tag(
      id: 'riley', name: 'Riley', colorIndex: 9, iconIndex: 10, sortOrder: 0),
  'moxify': Tag(
      id: 'moxify', name: 'Moxify', colorIndex: 6, iconIndex: 1, sortOrder: 1),
};

Task _task(String id, String title,
        {String? time,
        String? tagId,
        String date = _today,
        String? completedOnDate}) =>
    Task(
      id: id,
      title: title,
      date: date,
      createdDate: date,
      time: time,
      tagId: tagId,
      completedOnDate: completedOnDate,
    );

final _fixture = [
  _task('1', 'Vet appointment', time: '09:00'),
  _task('2', 'Fix Shipaton promo video', time: '17:00', tagId: 'moxify'),
  _task('3', 'Give Riley bath', time: '18:00', tagId: 'riley'),
  _task('4', 'Edit Cozy Zone', date: '2026-07-13'),
  _task('5', 'Make Shorts clip for CF and CZ', tagId: 'moxify'),
  _task('6', 'Set out blue and green can', completedOnDate: _today),
];

const _questions = [
  DailyQuestion(id: 'travel', label: 'Work travel', options: ['OV', 'Bike'],
      sortOrder: 0),
  DailyQuestion(id: 'gym', label: 'Cycled to the gym', options: [],
      sortOrder: 1),
];

Widget _day({
  List<Task>? tasks,
  String note = '',
  List<DailyQuestion> questions = const [],
  Map<String, String> answers = const {},
}) => Scaffold(
      body: SafeArea(
        child: DayView(
          dayKey: _today,
          today: _today,
          questions: questions,
          answers: answers,
          tasks: tasksForDay(tasks ?? _fixture, _today, _today),
          tags: _tags,
          note: note,
          onJump: (_) {},
          onToggle: (_) {},
          onMenu: (_) {},
          onAdd: (_, {tagId, time}) {},
          onNoteChanged: (_) {},
        ),
      ),
    );

/// Swipes near the top of the day content. Not at the centre: on a phone the
/// note's TextField sits there and claims horizontal drags for text selection.
Future<void> swipeToNextDay(WidgetTester tester) async {
  final page = tester.getRect(find.byType(PageView));
  await tester.flingFrom(
      Offset(page.center.dx, page.top + 30), const Offset(-400, 0), 1000);
  await tester.pumpAndSettle();
}

void main() {
  goldenForSizes(
    'day view',
    'day_view',
    GoldenSize.values,
    () => _day(
      note: 'Parchment release day!!!\n\nTook Riley to the vet this morning.',
    ),
  );

  goldenForSizes(
    'day view with the check-offs answered and folded beside the date',
    'day_view_questions_folded',
    [GoldenSize.phone, GoldenSize.mac],
    () => _day(
      questions: _questions,
      answers: const {'travel': 'Bike', 'gym': 'yes'},
    ),
  );

  goldenForSizes(
    'day view with the check-offs still to do',
    'day_view_questions_open',
    [GoldenSize.phone],
    () => _day(questions: _questions),
  );

  goldenForSizes(
    'day view on an empty day',
    'day_view_empty',
    [GoldenSize.phone],
    () => _day(tasks: const []),
  );

  testWidgets('day view in e-ink mode', (tester) async {
    configureSize(tester, GoldenSize.eink);
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: SeedlingTheme.eink(),
      home: _day(note: 'Took Riley to the vet this morning.'),
    ));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/day_view_eink_mode.png'));
  });

  testWidgets('splits tasks into the timed and untimed blocks',
      (tester) async {
    configureSize(tester, GoldenSize.phone);
    await tester.pumpWidget(wrapApp(_day()));

    expect(find.text('Vet appointment'), findsOneWidget);
    expect(find.text('Edit Cozy Zone'), findsOneWidget);
    expect(find.text('Nothing timed'), findsNothing);
  });

  testWidgets('reports the task whose checkbox was tapped', (tester) async {
    configureSize(tester, GoldenSize.phone);
    final toggled = <String>[];
    await tester.pumpWidget(wrapApp(Scaffold(
      body: SafeArea(
        child: DayView(
          dayKey: _today,
          today: _today,
          tasks: tasksForDay(_fixture, _today, _today),
          tags: _tags,
          note: '',
          onJump: (_) {},
          onToggle: (t) => toggled.add(t.title),
          onMenu: (_) {},
          onAdd: (_, {tagId, time}) {},
          onNoteChanged: (_) {},
        ),
      ),
    )));

    await tester.tap(find.byType(TaskCheckbox).first);

    expect(toggled, ['Vet appointment']);
  });

  group('wired to Firestore', () {
    late FakeFirebaseFirestore firestore;
    late SeedlingRepo repo;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repo = SeedlingRepo(firestore, 'bas');
    });

    testWidgets('shows today on open and checking a task stores this day',
        (tester) async {
      configureSize(tester, GoldenSize.phone);
      await repo.addTask('Afwas doen', date: todayKey());

      await tester.pumpWidget(wrapApp(DayPage(repo: repo)));
      await tester.pumpAndSettle();

      expect(find.text('Afwas doen'), findsOneWidget);

      await tester.tap(find.byType(TaskCheckbox).first);
      await tester.pumpAndSettle();

      final stored = (await repo.watchTasks().first).single;
      expect(stored.completedOnDate, todayKey());
    });

    testWidgets('unchecking on the day it was checked clears it',
        (tester) async {
      configureSize(tester, GoldenSize.phone);
      await repo.addTask('Afwas doen', date: todayKey());
      final task = (await repo.watchTasks().first).single;
      await repo.setCompleted(task, todayKey());

      await tester.pumpWidget(wrapApp(DayPage(repo: repo)));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TaskCheckbox).first);
      await tester.pumpAndSettle();

      expect((await repo.watchTasks().first).single.completedOnDate, isNull);
    });

    testWidgets('the header stays put while the days slide under it',
        (tester) async {
      configureSize(tester, GoldenSize.phone);
      await tester.pumpWidget(wrapApp(DayPage(repo: repo)));
      await tester.pumpAndSettle();

      final before = tester.getTopLeft(find.byType(DayHeader));

      await swipeToNextDay(tester);

      expect(tester.getTopLeft(find.byType(DayHeader)), before);
      expect(find.byType(DayHeader), findsOneWidget);
    });

    testWidgets('the pinned header follows a swipe to the next day',
        (tester) async {
      configureSize(tester, GoldenSize.phone);
      await tester.pumpWidget(wrapApp(DayPage(repo: repo)));
      await tester.pumpAndSettle();

      expect(selectedShortcutLabel(tester), 'Today');

      await swipeToNextDay(tester);

      expect(selectedShortcutLabel(tester), isNot('Today'));
    });

    testWidgets('going back from tomorrow to today slides towards the left',
        (tester) async {
      configureSize(tester, GoldenSize.phone);
      await tester.pumpWidget(wrapApp(DayPage(repo: repo)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tomorrow'));
      await tester.pumpAndSettle();
      expect(selectedShortcutLabel(tester), 'Tomorrow');

      final controller =
          tester.widget<PageView>(find.byType(PageView)).controller!;
      final from = controller.page!;

      await tester.tap(find.text('Today'));
      await tester.pump(); // let the animation start ticking
      await tester.pump(const Duration(milliseconds: 120));

      // Mid-animation the page must be heading down towards today, not up.
      expect(controller.page, lessThan(from));

      await tester.pumpAndSettle();
      expect(selectedShortcutLabel(tester), 'Today');
    });

    testWidgets('typing a task adds it to the day on screen', (tester) async {
      configureSize(tester, GoldenSize.phone);
      await tester.pumpWidget(wrapApp(DayPage(repo: repo)));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextField, 'Add a task…'), 'Water the plants');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      final stored = (await repo.watchTasks().first).single;
      expect(stored.title, 'Water the plants');
      expect(stored.date, todayKey());
    });
  });
}
