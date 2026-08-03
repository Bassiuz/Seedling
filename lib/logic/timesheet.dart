import '../models/calendar_event.dart';
import '../models/event_extras.dart';
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
    this.isEvent = false,
  });

  final String sourceId;
  final String title;

  /// A meeting line. [sourceId] is then the event's hide key, which is where
  /// its extras — the ticket and the minutes — live.
  final bool isEvent;

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
    final touched =
        minutes.any((m) => m > 0) ||
        days.contains(task.completedOnDate) ||
        days.contains(task.date);
    if (!touched) continue;
    rows.add(
      TimesheetRow(
        sourceId: task.id,
        title: task.title,
        jira: task.jira,
        minutes: minutes,
      ),
    );
  }

  rows.sort((a, b) => a.title.compareTo(b.title));
  return rows;
}

/// The meeting lines: a calendar event earns one when a ticket is attached
/// to it and the week has an occurrence. Grouped by hide key, the way extras
/// are stored, so a repeating meeting is one line with its days side by side.
///
/// An extras entry with hours in the week but no occurrence in [events] keeps
/// its line too — a machine that cannot read the calendar still sends those
/// hours to Jira, and hours that get sent should be hours you can see.
List<TimesheetRow> eventRows(
  List<CalendarEvent> events,
  Map<String, EventExtras> extras,
  String anyDay,
) {
  final days = weekDays(anyDay);
  final occurring = <String, CalendarEvent>{};
  for (final event in events) {
    if (days.contains(event.dayKey)) {
      occurring.putIfAbsent(event.hideKey, () => event);
    }
  }

  final rows = <TimesheetRow>[];
  for (final entry in extras.entries) {
    final extra = entry.value;
    if (extra.jira == null) continue;
    final minutes = [for (final day in days) extra.minutesOn(day)];
    final event = occurring[entry.key];
    if (event == null && !minutes.any((m) => m > 0)) continue;
    rows.add(
      TimesheetRow(
        sourceId: entry.key,
        title: event?.title ?? extra.title ?? entry.key,
        jira: extra.jira,
        isEvent: true,
        minutes: minutes,
      ),
    );
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

/// Minutes per day across every row.
List<int> dayTotals(List<TimesheetRow> rows) => [
  for (var day = 0; day < 7; day++)
    rows.fold(0, (sum, row) => sum + row.minutes[day]),
];

/// Which of the seven columns to draw: the working week, plus a weekend day
/// only if something is on it.
///
/// Nobody wants two empty columns every week, but an hour logged on a Sunday
/// that no grid shows is an hour that never reaches Jira — so it earns its
/// column rather than being dropped.
List<int> shownDays(List<TimesheetRow> rows) {
  final totals = dayTotals(rows);
  return [
    for (var day = 0; day < 7; day++)
      if (day < 5 || totals[day] > 0) day,
  ];
}
