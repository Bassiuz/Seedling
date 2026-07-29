import 'dart:convert';

import '../models/calendar_event.dart';
import '../models/tag.dart';
import '../models/task.dart';

/// One line on the widget's left column.
class WidgetEvent {
  const WidgetEvent({required this.time, required this.title});

  /// `HH:mm`, or "all day".
  final String time;
  final String title;

  Map<String, dynamic> toMap() => {'time': time, 'title': title};
}

/// One line on the right column. Carries its id, because the widget can check
/// it off and something has to know which task that was.
class WidgetTask {
  const WidgetTask({required this.id, required this.title, this.tag});

  final String id;
  final String title;
  final String? tag;

  Map<String, dynamic> toMap() => {'id': id, 'title': title, 'tag': tag};
}

/// What the home-screen widget shows: today's appointments beside today's
/// open tasks.
///
/// Built as a pure function so the payload is testable without a device — the
/// widget itself can only really be checked by looking at a home screen.
class WidgetPayload {
  const WidgetPayload({
    required this.dayKey,
    required this.events,
    required this.tasks,
    required this.moreEvents,
    required this.moreTasks,
  });

  /// How many lines fit in one column of a four-by-two widget. Four is what
  /// fits without the text shrinking to something you would not read across a
  /// room, which is the only way a widget is ever read.
  static const int lines = 4;

  final String dayKey;
  final List<WidgetEvent> events;
  final List<WidgetTask> tasks;

  /// What did not fit, so each column can say "+3 more".
  final int moreEvents;
  final int moreTasks;

  Map<String, dynamic> toMap() => {
        'dayKey': dayKey,
        'events': [for (final e in events) e.toMap()],
        'tasks': [for (final t in tasks) t.toMap()],
        'moreEvents': moreEvents,
        'moreTasks': moreTasks,
      };

  String toJson() => jsonEncode(toMap());
}

/// [tasks] and [events] should already be filtered to the day.
///
/// Anything checked off is left out: the widget is what is left of the day,
/// and a glance should not have to skip past what is done.
WidgetPayload buildWidgetPayload({
  required String dayKey,
  required List<Task> tasks,
  required List<CalendarEvent> events,
  Map<String, Tag> tags = const {},
  Set<String> doneEvents = const {},
  Set<String> pendingDone = const {},
}) {
  // All-day things first, then by the clock, the way the day is lived.
  final timed = [
    for (final event in events)
      if (!doneEvents.contains(event.id)) event,
  ]..sort((a, b) {
      if (a.allDay != b.allDay) return a.allDay ? -1 : 1;
      return (a.time ?? '').compareTo(b.time ?? '');
    });

  final open = [
    for (final task in tasks)
      if (!task.isCompleted && !pendingDone.contains(task.id)) task,
  ];

  return WidgetPayload(
    dayKey: dayKey,
    events: [
      for (final event in timed.take(WidgetPayload.lines))
        WidgetEvent(
          time: event.allDay ? 'all day' : event.time ?? '',
          title: event.title,
        ),
    ],
    moreEvents: (timed.length - WidgetPayload.lines).clamp(0, 99),
    tasks: [
      for (final task in open.take(WidgetPayload.lines))
        WidgetTask(
          id: task.id,
          title: task.title,
          tag: tags[task.tagId]?.name,
        ),
    ],
    moreTasks: (open.length - WidgetPayload.lines).clamp(0, 99),
  );
}
