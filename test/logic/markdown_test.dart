import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/logic/markdown.dart';
import 'package:seedling/models/calendar_event.dart';
import 'package:seedling/models/daily_question.dart';
import 'package:seedling/models/review_template.dart';
import 'package:seedling/models/someday_item.dart';
import 'package:seedling/models/tag.dart';
import 'package:seedling/models/task.dart';
import 'package:seedling/models/week_review.dart';

const _day = '2026-07-27';
const _tags = {
  'moxify':
      Tag(id: 'moxify', name: 'Moxify', colorIndex: 6, iconIndex: 1, sortOrder: 0),
};

Task _task(
  String title, {
  String? tagId,
  String? time,
  String date = _day,
  String? completedOnDate,
  Map<String, int> entries = const {},
}) =>
    Task(
      id: title,
      title: title,
      date: date,
      createdDate: date,
      tagId: tagId,
      time: time,
      completedOnDate: completedOnDate,
      timeEntries: entries,
    );

void main() {
  group('a day', () {
    test('carries front matter a tool can read', () {
      final md = dayMarkdown(
          dayKey: _day, tasks: const [], tags: _tags, note: '');

      expect(md, startsWith('---\ndate: 2026-07-27\nweekday: Monday\n---'));
    });

    test('writes checkboxes that reflect completion', () {
      final md = dayMarkdown(
        dayKey: _day,
        tasks: [
          _task('Afwas doen'),
          _task('Water the greenhouse', completedOnDate: _day),
        ],
        tags: _tags,
        note: '',
      );

      expect(md, contains('- [ ] Afwas doen'));
      expect(md, contains('- [x] Water the greenhouse'));
    });

    test('annotates tag, time, logged minutes and where it came from', () {
      final md = dayMarkdown(
        dayKey: _day,
        tasks: [
          _task('Fix promo video',
              tagId: 'moxify',
              time: '17:00',
              date: '2026-07-25',
              entries: const {_day: 90}),
        ],
        tags: _tags,
        note: '',
      );

      expect(md, contains('#Moxify'));
      expect(md, contains('17:00'));
      expect(md, contains('1h 30m'));
      expect(md, contains('from 2026-07-25'));
    });

    test('records the day a task was finished when it was a later one', () {
      final md = dayMarkdown(
        dayKey: _day,
        tasks: [_task('Afwas doen', completedOnDate: '2026-07-28')],
        tags: _tags,
        note: '',
      );

      expect(md, contains('done 2026-07-28'));
    });

    test('lists the agenda with all-day events called out', () {
      final md = dayMarkdown(
        dayKey: _day,
        tasks: const [],
        tags: _tags,
        note: '',
        events: const [
          CalendarEvent(
              id: '1', title: "Sam's birthday", dayKey: _day, allDay: true),
          CalendarEvent(
              id: '2',
              title: 'Dentist appointment',
              dayKey: _day,
              allDay: false,
              time: '09:00'),
        ],
      );

      expect(md, contains('- All day — '));
      expect(md, contains('- 09:00 — Dentist appointment'));
    });

    test('writes the note through untouched', () {
      const note = 'Release day!!!\n\n- a list\n- **bold**';
      final md = dayMarkdown(
          dayKey: _day, tasks: const [], tags: _tags, note: note);

      expect(md, contains(note));
    });

    test('leaves out sections that have nothing in them', () {
      final md = dayMarkdown(
          dayKey: _day, tasks: const [], tags: _tags, note: '   ');

      expect(md, isNot(contains('## Tasks')));
      expect(md, isNot(contains('## Note')));
      expect(md, isNot(contains('## Agenda')));
    });

    test('spells out answered questions and skips unanswered ones', () {
      final md = dayMarkdown(
        dayKey: _day,
        tasks: const [],
        tags: _tags,
        note: '',
        questions: const [
          DailyQuestion(
              id: 'travel',
              label: 'Work travel',
              emoji: '🚲',
              options: ['Home', 'Bike'],
              sortOrder: 0),
          DailyQuestion(
              id: 'gym', label: 'Moved my body', options: [], sortOrder: 1),
          DailyQuestion(
              id: 'unasked', label: 'Never answered', options: [], sortOrder: 2),
        ],
        answers: const {'travel': 'Bike', 'gym': 'yes'},
      );

      expect(md, contains('- 🚲 Work travel: Bike'));
      expect(md, contains('- Moved my body: yes'));
      expect(md, isNot(contains('Never answered')));
    });
  });

  group('a week review', () {
    test('quotes the goals as they stood and keeps the observations', () {
      final md = reviewMarkdown(WeekReview(
        weekKey: '2026-W31',
        goals: const [
          GoalBlock(title: 'Yearly Goals', goals: ['100 monthly users']),
        ],
        answers: const {'What did I do?': 'Got back on track'},
        moodLines: const [MoodLine(emoji: '😄', text: 'Work is better')],
      ));

      expect(md, contains('# Week review 2026-W31'));
      expect(md, contains('## Yearly Goals'));
      expect(md, contains('> 100 monthly users'));
      expect(md, contains('## What did I do?'));
      expect(md, contains('Got back on track'));
      expect(md, contains('😄 Work is better'));
    });

    test('skips a question that was left blank', () {
      final md = reviewMarkdown(const WeekReview(
        weekKey: '2026-W31',
        answers: {'Answered': 'yes', 'Blank': '   '},
      ));

      expect(md, contains('## Answered'));
      expect(md, isNot(contains('## Blank')));
    });
  });

  group('someday and tags', () {
    test('a project list names the project', () {
      final md = somedayMarkdown(_tags['moxify'], const [
        SomedayItem(id: '1', title: 'Importer rewrite', priority: 0),
      ]);

      expect(md, contains('# Someday — Moxify'));
      expect(md, contains('- Importer rewrite'));
    });

    test('the untagged list still has a heading', () {
      expect(somedayMarkdown(null, const []), contains('No project'));
    });

    test('projects are listed for the agent to read', () {
      expect(tagsMarkdown(_tags.values.toList()), contains('- Moxify'));
    });
  });

  group('paths', () {
    test('days are filed under their year', () {
      expect(dayPath('2026-07-27'), 'days/2026/2026-07-27.md');
    });

    test('reviews and someday lists get stable names', () {
      expect(reviewPath('2026-W31'), 'reviews/2026-W31.md');
      expect(somedayPath(_tags['moxify']), 'someday/moxify.md');
      expect(somedayPath(null), 'someday/no-project.md');
    });
  });
}
