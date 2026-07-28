import '../models/calendar_event.dart';
import '../models/task.dart';

/// One line in the Timed block. It is either an appointment read from the
/// calendar or a task you gave a time to — the day does not care which, and
/// neither should the ordering.
class TimedEntry {
  const TimedEntry.event(CalendarEvent this.event) : task = null;
  const TimedEntry.task(Task this.task) : event = null;

  final CalendarEvent? event;
  final Task? task;

  bool get isEvent => event != null;
  bool get allDay => event?.allDay ?? false;
  String? get time => event?.time ?? task?.time;
  String get title => event?.title ?? task!.title;

  /// Stable across rebuilds, and unique between an event and a task that
  /// happen to share a title.
  String get id => isEvent ? 'event:${event!.id}' : 'task:${task!.id}';
}

/// Everything with a time on it, in the order the day actually happens.
///
/// Appointments and tasks are interleaved rather than grouped: a 09:00 task
/// belongs above an 18:00 appointment, which is not what you get from listing
/// one kind after the other.
List<TimedEntry> timedEntries(List<CalendarEvent> events, List<Task> tasks) {
  final entries = <TimedEntry>[
    for (final event in events) TimedEntry.event(event),
    for (final task in tasks)
      if (task.isTimed) TimedEntry.task(task),
  ];

  entries.sort((a, b) {
    // All-day things head the list; they frame the day rather than sit in it.
    if (a.allDay != b.allDay) return a.allDay ? -1 : 1;
    final byTime = (a.time ?? '').compareTo(b.time ?? '');
    if (byTime != 0) return byTime;
    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  });

  return entries;
}
