import '../models/calendar_event.dart';
import '../models/daily_question.dart';
import '../models/someday_item.dart';
import '../models/tag.dart';
import '../models/task.dart';
import '../models/week_review.dart';
import 'day_key.dart';

/// Renders Seedling's data as Markdown for the vault.
///
/// One-way: these files are written for you and for whatever agent you point at
/// them, and never read back. Everything is plain text with a little YAML front
/// matter, so `grep` and an LLM both cope.

String _frontMatter(Map<String, String> fields) => [
      '---',
      for (final e in fields.entries) '${e.key}: ${e.value}',
      '---',
      '',
    ].join('\n');

/// Minutes as "1h 30m", matching what the app shows.
String _duration(int minutes) {
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (hours == 0) return '${rest}m';
  if (rest == 0) return '${hours}h';
  return '${hours}h ${rest}m';
}

String _taskLine(Task task, Map<String, Tag> tags, String dayKey) {
  final box = task.completedOnDate == null ? '[ ]' : '[x]';
  final parts = <String>[
    if (task.time != null) task.time!,
    if (task.tagId != null) '#${tags[task.tagId]?.name ?? task.tagId}',
    if (task.minutesOn(dayKey) > 0) _duration(task.minutesOn(dayKey)),
    if (task.date != dayKey) 'from ${task.date}',
    if (task.completedOnDate != null && task.completedOnDate != dayKey)
      'done ${task.completedOnDate}',
  ];
  final suffix = parts.isEmpty ? '' : '  _(${parts.join(' · ')})_';
  return '- $box ${task.title}$suffix';
}

/// One day page.
String dayMarkdown({
  required String dayKey,
  required List<Task> tasks,
  required Map<String, Tag> tags,
  required String note,
  List<CalendarEvent> events = const [],
  List<DailyQuestion> questions = const [],
  Map<String, String> answers = const {},
}) {
  final date = dateOfKey(dayKey);
  final buffer = StringBuffer()
    ..write(_frontMatter({
      'date': dayKey,
      'weekday': _weekdayName(date.weekday),
    }))
    ..writeln('# $dayKey');

  if (events.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('## Agenda');
    for (final event in events) {
      final when = event.allDay ? 'All day' : event.time ?? '';
      buffer.writeln('- $when — ${event.title}');
    }
  }

  if (tasks.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('## Tasks');
    for (final task in tasks) {
      buffer.writeln(_taskLine(task, tags, dayKey));
    }
  }

  final answered =
      questions.where((q) => (answers[q.id] ?? '').isNotEmpty).toList();
  if (answered.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('## Daily');
    for (final question in answered) {
      final value = answers[question.id]!;
      final shown =
          question.isCheck && value == DailyQuestion.checked ? 'yes' : value;
      final emoji = question.emoji == null ? '' : '${question.emoji} ';
      buffer.writeln('- $emoji${question.label}: $shown');
    }
  }

  if (note.trim().isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('## Note')
      ..writeln()
      // Verbatim: the note is already markdown, and rewriting it would lose
      // whatever the writer meant.
      ..writeln(note.trimRight());
  }

  return buffer.toString();
}

/// One week review.
String reviewMarkdown(WeekReview review) {
  final buffer = StringBuffer()
    ..write(_frontMatter({'week': review.weekKey}))
    ..writeln('# Week review ${review.weekKey}');

  for (final block in review.goals) {
    buffer
      ..writeln()
      ..writeln('## ${block.title}');
    for (final goal in block.goals) {
      buffer.writeln('> $goal');
      buffer.writeln();
    }
  }

  if (review.answers.isNotEmpty) {
    for (final entry in review.answers.entries) {
      if (entry.value.trim().isEmpty) continue;
      buffer
        ..writeln()
        ..writeln('## ${entry.key}')
        ..writeln()
        ..writeln(entry.value.trimRight());
    }
  }

  if (review.moodLines.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('## Observations')
      ..writeln();
    for (final line in review.moodLines) {
      buffer.writeln('${line.emoji} ${line.text}');
      buffer.writeln();
    }
  }

  return buffer.toString();
}

/// The someday list for one project. [tag] null means the untagged group.
String somedayMarkdown(Tag? tag, List<SomedayItem> items) {
  final name = tag?.name ?? 'No project';
  final buffer = StringBuffer()
    ..write(_frontMatter({'project': name}))
    ..writeln('# Someday — $name')
    ..writeln();
  for (final item in items) {
    buffer.writeln('- ${item.title}');
  }
  return buffer.toString();
}

/// The project list itself.
String tagsMarkdown(List<Tag> tags) {
  final buffer = StringBuffer()
    ..write(_frontMatter({'kind': 'tags'}))
    ..writeln('# Projects')
    ..writeln();
  for (final tag in tags) {
    buffer.writeln('- ${tag.name}');
  }
  return buffer.toString();
}

/// Where a day's file belongs, relative to the vault root. Years are folders so
/// a decade of days stays browsable.
String dayPath(String dayKey) => 'days/${dayKey.substring(0, 4)}/$dayKey.md';

String reviewPath(String weekKey) => 'reviews/$weekKey.md';

String somedayPath(Tag? tag) =>
    'someday/${tag == null ? 'no-project' : tag.id}.md';

String _weekdayName(int weekday) => const [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ][weekday - 1];
