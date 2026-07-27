import 'dart:convert';

import '../models/calendar_event.dart';
import '../models/tag.dart';
import '../models/task.dart';

/// What the home-screen widget shows: the next thing with a time on it, and the
/// first few things still to do.
///
/// Built as a pure function so the payload is testable without a device — the
/// widget itself can only be checked by looking at a home screen.
class WidgetPayload {
  const WidgetPayload({
    required this.dayKey,
    required this.next,
    required this.tasks,
    required this.remaining,
  });

  /// How many task lines the widget has room for.
  static const int taskLines = 4;

  final String dayKey;

  /// "09:00 Vet appointment", or null when nothing is scheduled.
  final String? next;
  final List<String> tasks;

  /// Tasks that did not fit, so the widget can say "+3 more".
  final int remaining;

  Map<String, dynamic> toMap() => {
        'dayKey': dayKey,
        'next': next,
        'tasks': tasks,
        'remaining': remaining,
      };

  String toJson() => jsonEncode(toMap());
}

/// [tasks] and [events] should already be filtered to the day.
WidgetPayload buildWidgetPayload({
  required String dayKey,
  required List<Task> tasks,
  required List<CalendarEvent> events,
  Map<String, Tag> tags = const {},
}) {
  final open = tasks.where((t) => !t.isCompleted).toList();

  // The next timed thing, whether it is an appointment or a task with a time.
  final timed = <(String, String)>[
    for (final event in events)
      if (!event.allDay && event.time != null) (event.time!, event.title),
    for (final task in open)
      if (task.time != null) (task.time!, task.title),
  ]..sort((a, b) => a.$1.compareTo(b.$1));

  final untimed = open.where((t) => t.time == null).toList();
  final shown = untimed.take(WidgetPayload.taskLines).toList();

  return WidgetPayload(
    dayKey: dayKey,
    next: timed.isEmpty ? null : '${timed.first.$1} ${timed.first.$2}',
    tasks: [
      for (final task in shown)
        task.tagId == null
            ? task.title
            : '${task.title} · ${tags[task.tagId]?.name ?? ''}'.trimRight(),
    ],
    remaining: untimed.length - shown.length,
  );
}
