import 'package:flutter/material.dart';

import '../logic/event_time.dart';
import '../logic/rollover.dart';
import '../logic/timed_entries.dart';
import '../models/calendar_event.dart';
import '../models/tag.dart';
import '../models/task.dart';
import '../theme/seedling_palette.dart';
import '../theme/seedling_theme.dart';
import 'add_task_field.dart';
import 'block_frame.dart';
import 'task_tile.dart';

/// Everything on the day that happens at a time, in the order it happens.
///
/// Appointments and timed tasks are interleaved rather than grouped, and both
/// can be ticked off — an appointment's tick lives in Seedling, since the
/// calendar itself is only ever read.
class TimedBlock extends StatelessWidget {
  const TimedBlock({
    super.key,
    required this.tasks,
    required this.tags,
    required this.shownDay,
    required this.onToggle,
    required this.onMenu,
    this.events = const [],
    this.onEventMenu,
    this.onUnhideEvent,
    this.onToggleEvent,
    this.doneEvents = const {},
    this.hiddenKeys = const {},
    this.today,
    this.now,
    this.onAdd,
  });

  final List<CalendarEvent> events;

  /// Opens the event's menu. Hiding lives in there rather than on the gesture:
  /// a long press used to hide an appointment outright, with no confirmation
  /// and no hint that it had happened.
  final void Function(CalendarEvent)? onEventMenu;
  final void Function(CalendarEvent)? onUnhideEvent;

  /// Ticking an appointment off. Null leaves them read-only.
  final void Function(CalendarEvent, bool done)? onToggleEvent;
  final Set<String> doneEvents;

  final Set<String> hiddenKeys;

  /// Today's key and the current `HH:mm`. Both null in tests that do not care;
  /// nothing is drawn as overdue without them.
  final String? today;
  final String? now;

  /// Adding something straight into the timed list. Null hides the add line.
  final void Function(String title, {String? tagId, String? time})? onAdd;

  final List<Task> tasks;
  final Map<String, Tag> tags;
  final String shownDay;
  final void Function(Task) onToggle;
  final void Function(Task) onMenu;

  bool _overdue(TimedEntry entry) {
    if (today == null || now == null) return false;
    final done = entry.isEvent
        ? doneEvents.contains(entry.event!.id)
        : entry.task!.isCompleted;
    if (done) return false;
    return isOverdue(
      day: shownDay,
      time: entry.time,
      today: today!,
      now: now!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = timedEntries(events, tasks);

    return BlockFrame(
      title: 'Timed',
      icon: Icons.schedule,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (entries.isEmpty && onAdd == null)
            const EmptyNote('Nothing timed')
          else ...[
            for (final entry in entries)
              if (entry.isEvent)
                EventRow(
                  event: entry.event!,
                  hidden: hiddenKeys.contains(entry.event!.hideKey),
                  done: doneEvents.contains(entry.event!.id),
                  overdue: _overdue(entry),
                  onToggle: onToggleEvent == null
                      ? null
                      : (done) => onToggleEvent!(entry.event!, done),
                  onMenu: onEventMenu == null
                      ? null
                      : () => onEventMenu!(entry.event!),
                  onUnhide: onUnhideEvent == null
                      ? null
                      : () => onUnhideEvent!(entry.event!),
                )
              else
                TaskTile(
                  task: entry.task!,
                  shownDay: shownDay,
                  tag: tags[entry.task!.tagId],
                  overdue: _overdue(entry),
                  onToggle: () => onToggle(entry.task!),
                  onMenu: () => onMenu(entry.task!),
                ),
          ],
          if (onAdd != null)
            AddTaskField(
              onAdd: onAdd!,
              tags: tags.values.toList(),
              requireTime: true,
            ),
        ],
      ),
    );
  }
}

/// One appointment.
///
/// Ticking it marks it done in Seedling only — your calendar is never written
/// to. Long-press hides it for good.
class EventRow extends StatelessWidget {
  const EventRow({
    super.key,
    required this.event,
    this.hidden = false,
    this.done = false,
    this.overdue = false,
    this.onToggle,
    this.onMenu,
    this.onUnhide,
  });

  final CalendarEvent event;

  /// Only ever true while hidden events are being revealed; otherwise a
  /// hidden event is filtered out before it reaches here.
  final bool hidden;
  final bool done;
  final bool overdue;
  final void Function(bool done)? onToggle;

  /// Long press or right click. Opens a menu rather than hiding outright.
  final VoidCallback? onMenu;
  final VoidCallback? onUnhide;

  @override
  Widget build(BuildContext context) {
    final colors = SeedlingColors.of(context);
    final text = Theme.of(context).textTheme;
    final titleColour = hidden
        ? colors.faint
        : done
            ? colors.muted
            : colors.ink;

    return GestureDetector(
      onLongPress: onMenu,
      onSecondaryTap: onMenu,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (onToggle == null || hidden)
              SizedBox(
                width: 28,
                child: Icon(
                  event.allDay ? Icons.event : Icons.schedule,
                  size: 20,
                  color: hidden ? colors.faint : colors.muted,
                ),
              )
            else
              TaskCheckbox(
                state: done
                    ? TaskCheckState.checkedHere
                    : TaskCheckState.open,
                color: overdue ? SeedlingPalette.red : colors.ink,
                onTap: () => onToggle!(!done),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      event.title,
                      style: text.bodyLarge?.copyWith(
                        color: titleColour,
                        decoration:
                            done ? TextDecoration.lineThrough : null,
                        decorationColor: colors.muted,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      [
                        if (event.allDay) 'All day' else event.time ?? '',
                        if (overdue) 'Overdue',
                        if (hidden) 'hidden',
                      ].where((p) => p.isNotEmpty).join(' · '),
                      style: text.labelSmall?.copyWith(
                        color: overdue ? SeedlingPalette.red : null,
                        fontWeight: overdue ? FontWeight.w600 : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (hidden && onUnhide != null)
              IconButton(
                tooltip: 'Show this again',
                onPressed: onUnhide,
                icon: Icon(Icons.undo, size: 18, color: colors.muted),
              ),
          ],
        ),
      ),
    );
  }
}
