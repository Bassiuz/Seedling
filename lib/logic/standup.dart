import '../models/calendar_event.dart';
import '../models/task.dart';
import 'day_key.dart';
import 'rollover.dart';

/// What you would read out at a standup: what you finished the day before,
/// and what you have taken on for this one.
class Standup {
  const Standup({
    required this.day,
    required this.previousDay,
    required this.done,
    required this.planned,
    this.attended = const [],
    this.meetings = const [],
  });

  final String day;
  final String previousDay;

  /// Checked off on [previousDay], whichever day it was planned for.
  final List<Task> done;

  /// On [day]'s list, finished or not — a standup is what you are on, not
  /// only what is left.
  final List<Task> planned;

  /// Yesterday's appointments, in the order they happened. A meeting on the
  /// calendar counts as attended: there is nothing to tick, and a standup
  /// where the meetings are missing is a standup that reads as an idle day.
  final List<CalendarEvent> attended;

  /// Today's appointments, in the order they come.
  final List<CalendarEvent> meetings;
}

/// Builds it from every task there is.
///
/// [previousDay] is the calendar day before, not the last working day: a
/// Monday standup covering only Sunday is a choice for the person reading it,
/// not for Seedling.
Standup standupFor(
  List<Task> all,
  String day, {
  List<CalendarEvent> events = const [],
  List<CalendarEvent> previousEvents = const [],
}) {
  final previous = addDays(day, -1);
  return Standup(
    day: day,
    previousDay: previous,
    attended: _inOrder(previousEvents),
    meetings: _inOrder(events),
    done: [
      for (final task in all)
        if (task.completedOnDate == previous) task,
    ]..sort((a, b) => a.title.compareTo(b.title)),
    planned: tasksForDay(all, day, day),
  );
}

/// All-day things first, then by the clock — the order they were lived in.
List<CalendarEvent> _inOrder(List<CalendarEvent> events) =>
    [...events]..sort((a, b) {
      if (a.allDay != b.allDay) return a.allDay ? -1 : 1;
      return (a.time ?? '').compareTo(b.time ?? '');
    });

/// The standup as a block of text to paste into Slack.
///
/// Slack turns "- " into a bullet and a four-space indent into a sub-bullet,
/// which is the shape a standup is read in. Meetings come first in each
/// section, same as on screen, and without their times: nobody reads the
/// clock out.
String standupText(Standup standup, {String name = ''}) {
  final buffer = StringBuffer();
  if (name.trim().isNotEmpty) buffer.writeln('${name.trim()}:');

  void section(String heading, List<String> lines) {
    buffer.writeln('- $heading');
    for (final line in lines) {
      buffer.writeln('    - $line');
    }
  }

  section('Gisteren:', [
    for (final event in standup.attended) event.title,
    for (final task in standup.done) task.title,
  ]);
  section('Vandaag:', [
    for (final event in standup.meetings) event.title,
    for (final task in standup.planned) task.title,
  ]);

  return buffer.toString().trimRight();
}
