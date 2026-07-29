import '../models/task.dart';
import '../models/topic.dart';
import 'day_key.dart';
import 'jira_ref.dart';
import 'week_key.dart';

/// One line of the timesheet: what it is, where it goes in Jira, and how much
/// of each day it took.
class TimesheetRow {
  const TimesheetRow({
    required this.sourceId,
    required this.title,
    required this.minutes,
    this.jira,
    this.topic,
  });

  final String sourceId;
  final String title;

  /// Seven entries, Monday first.
  final List<int> minutes;
  final JiraRef? jira;

  /// Set on the standing rows, so the screen can edit or remove them.
  final Topic? topic;

  int get total => minutes.fold(0, (sum, m) => sum + m);
}

/// The seven day keys of the week [anyDay] falls in, Monday first.
List<String> weekDays(String anyDay) {
  final monday = weekStartOf(anyDay);
  return [for (var i = 0; i < 7; i++) addDays(monday, i)];
}

/// The task lines for a week.
///
/// A task earns a line when it has a ticket and the week touched it: time
/// logged, checked off, or planned. Planned counts because the row has to
/// exist before you can put a number in it.
List<TimesheetRow> taskRows(List<Task> tasks, String anyDay) {
  final days = weekDays(anyDay);
  final rows = <TimesheetRow>[];

  for (final task in tasks) {
    if (task.jira == null) continue;
    final minutes = [for (final day in days) task.minutesOn(day)];
    final touched = minutes.any((m) => m > 0) ||
        days.contains(task.completedOnDate) ||
        days.contains(task.date);
    if (!touched) continue;
    rows.add(TimesheetRow(
      sourceId: task.id,
      title: task.title,
      jira: task.jira,
      minutes: minutes,
    ));
  }

  rows.sort((a, b) => a.title.compareTo(b.title));
  return rows;
}

/// The standing lines. Always all of them, in their own order: an empty row
/// is where you put this week's hours.
List<TimesheetRow> topicRows(List<Topic> topics, String anyDay) {
  final days = weekDays(anyDay);
  return [
    for (final topic in topics)
      TimesheetRow(
        sourceId: topic.id,
        title: topic.title,
        jira: topic.jira,
        topic: topic,
        minutes: [for (final day in days) topic.minutesOn(day)],
      ),
  ];
}

/// Minutes per day across every row, and the week's total.
List<int> dayTotals(List<TimesheetRow> rows) => [
      for (var day = 0; day < 7; day++)
        rows.fold(0, (sum, row) => sum + row.minutes[day]),
    ];
